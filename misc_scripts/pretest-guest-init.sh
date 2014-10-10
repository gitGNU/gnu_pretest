#!/bin/sh

# Hack for GNU-Hurd:
# mounted CDROM filesystems (using /hurd/iso9660fs) are always listed
# as upper-case. Set to non-empty to convert all PATHs to upper-case.
upper_case=

BASE=$(basename "$0")

die()
{
    echo "$BASE: error: $@" >&2
    exit 1
}

log()
{
    echo "$BASE: $@" >&2
}

# Input parameters:
#   $1 = CDROM device (e.g. '/dev/cd0a')
#   $2 = mount point
#   $3 = optional: mount parameters
mount_cdrom()
{
    test -e "$1" \
        || die "Expected CD device ($1) not found"
    test -d "$2" \
        || die "CD Mount direcotry ($2) not found"
    mount $3 "$1" "$2" \
        || log "Mounting CDROM ($1) failed. aborting."
}

# Parameters:
#   $1 = cdrom device
#   $2 = mount directory
mount_hurd_cdrom()
{
    test -e "$1" \
        || die "Expected CD device ($1) not found"
    test -d "$2" \
        || die "CD Mount direcotry ($2) not found"
    settrans "$2" /hurd/iso9660fs "$1" \
        || log "Mounting CDROM ($1) with settrans failed. aborting."
}

# Parameters
#  $1 - CD device
#  $2 - directory
minix_isodir_exists()
{
    isodir "$1" "$2" >/dev/null 2>&1
}

copy_minix_cdrom()
{
    # Connect device to service
    # https://groups.google.com/d/msg/Minix3/Sz90JJ1aoK8/8YzEONyBMYkJ
    # The device is tightly coupled to PreTest's configuration of
    # virtio disk and IDE "-cdrom" drive.
    MINIXCDDEV=/dev/c1d2
    service -c up /service/at_wini -dev "$MINIXCDDEV" -label at_wini

    # Check CDROM device accessibility
    minix_isodir_exists "$MINIXCDDEV" "/" \
        || die "failed to access CDROM at device $MINIXCDDEV"

    minix_isodir_exists "$MINIXCDDEV" "/pretest/" \
	    || die "Pretest-Init dir (/pretest/) not found on $MINIXCDDEV. aborting."

    __dir=$(mktemp -d -t pretest) || die "failed to create temporary directory"
    mkdir "$__dir/pretest/" || die "mkdir '$__dir/pretest/' failed"

    for DIR in keys scripts rscripts ;
    do
        minix_isodir_exists "$MINIXCDDEV" "/pretest/$DIR" || continue

        mkdir "$__dir/pretest/$DIR" || dir "mkdir '$__dir/pretest/$DIR' failed"
        FILES=$(isodir "$MINIXCDDEV" "/pretest/$DIR")
        for FILE in $FILES ;
        do
            isoread "$MINIXCDDEV" "/pretest/$DIR/$FILE" > "$__dir/pretest/$DIR/$FILE" \
                || die "isoread failed on '$MINIXCDDEV' and '/pretest/$DIR/$FILE'"
        done
    done

    # Copying done, set new fake 'mount dir'
    # TODO: delete it after script is done (with a trap?)
    MOUNTDIR=$__dir
}

# Mount CDROMs on different kernels/systems.
# Hack note:
# The device name is tightly coupled with PreTest's set-up:
# 1. On all systems (except GNU Hurd), the disk is connected as virtio,
#    And the CDROM is mounted with "-cdrom" => it will be the first IDE drive.
# 2. On GNU Hurd, the disk is connected as "-hda", so the cd device will
#    be the other IDE device (/dev/hd2)
# TODO:
# 1. auto-detect device on DilOS, GNU Hurd.
# 2. Future MINIX might be able to mount CDROMs, need to check version as well.
# 3. Do all known 'linux' systems auto-enable '/dev/cdrom' ?
mount_system_cdrom()
{
    UNAME=$(uname -s) || die "failed to get uname-s"
    MOUNTDIR=/mnt/
    case "$UNAME" in
        FreeBSD)        mount_cdrom "/dev/cd0" "$MOUNTDIR" "-t cd9660" ;;
        NetBSD|OpenBSD) mount_cdrom "/dev/cd0a" "$MOUNTDIR" ;;
        SunOS)          mount_cdrom "/dev/dsk/c0t0d0s0" "$MOUNTDIR" "-r -F hsfs" ;;
        Linux)          mount_cdrom "/dev/cdrom" "$MOUNTDIR" ;; #at least on debian?
        GNU)            mount_hurd_cdrom "/dev/hd2" "$MOUNTDIR"
                        upper_case=yes
                        ;;
        Minix)          copy_minix_cdrom
                        ;;
        *)          die "don't know which CDDEV to use for system '$UNAME'" ;;
    esac
}

set_directory_names()
{
    if test "x$upper_case" = "xyes" ; then
        INITDIR="$MOUNTDIR/PRETEST"
        KEYSDIR="$INITDIR/KEYS"
        RSCRIPTSDIR="$INITDIR/RSCRIPTS"
        SCRIPTSDIR="$INITDIR/SCRIPTS"
    else
        INITDIR="$MOUNTDIR/pretest"
        KEYSDIR="$INITDIR/keys"
        RSCRIPTSDIR="$INITDIR/rscripts"
        SCRIPTSDIR="$INITDIR/scripts"
    fi
}

verify_pretest_directory()
{
    test -d "$INITDIR" \
	    || die "Pretest-Init dir ($INITDIR) doesn't exist. aborting."
}


##
## Script start
##
mount_system_cdrom

set_directory_names

verify_pretest_directory


##
## Add keys, if exist
##
HOMEDIR=~miles

if test -d "$KEYSDIR" ; then
	log "adding SSH keys..."
    if ! test -d "$HOMEDIR/.ssh" ; then
        mkdir "$HOMEDIR/.ssh" || die "failed to create .ssh dir '$HOMEDIR/.ssh'"
        chown miles "$HOMEDIR/.ssh" || die "chown failed"
        chmod 0700 "$HOMEDIR/.ssh" || die "chmod failed"
    fi
    NEEDREOWN=no
    test -e "$HOMEDIR/.ssh/authorized_keys" || NEEDREOWN=yes
	find "$KEYSDIR" -type f -print | xargs cat >> "$HOMEDIR/.ssh/authorized_keys"
    if test "x$NEEDREOWN" = "xyes" ; then
        chown miles "$HOMEDIR/.ssh/authorized_keys"
	    chmod 0600 "$HOMEDIR/.ssh/authorized_keys"
    fi
	log "adding SSH keys - done"
else
	log "no SSH keys found ($KEYSDIR)"
fi

##
## Run Root scripts
##
if test -d "$RSCRIPTSDIR" ; then
	log "Running root-scripts...."
	for i in $(find "$RSCRIPTSDIR" -type f | sort) ;
	do
		log "Running root-script '$i'..."
		sh "$i"
	done
	log "Running root-scripts - done"
else
	log "no Root scripts found."
fi

##
## Run User scripts as 'miles'
##
if test -d "$SCRIPTSDIR" ; then
	log "Running (non-root) scripts...."
	for i in $(find "$SCRIPTSDIR" -type f | sort) ;
	do
		log "Running script '$i'..."
		su "miles" -c "$i"
	done
	log "Running scripts - done"
else
	log "no (non-root) scripts found."
fi

## vim: set shiftwidth=4:
## vim: set tabstop=4:
## vim: set expandtab:
