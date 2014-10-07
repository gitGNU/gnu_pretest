#!/bin/sh

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

UNAME=$(uname -s) || die "failed to get uname-s"
MOUNTDIR=/mnt/
case "$UNAME" in
    FreeBSD)        mount_cdrom "/dev/cd0" "$MOUNTDIR" "-t cd9660" ;;
    NetBSD|OpenBSD) mount_cdrom "/dev/cd0a" "$MOUNTDIR" ;;
    SunOS)          mount_cdrom "/dev/dsk/c0t0d0s0" "$MOUNTDIR" "-r -F hsfs" ;;
    Linux)          mount_cdrom "/dev/cdrom" "$MOUNTDIR" ;; #at least on debian?
    *)          die "don't know which CDDEV to use for system '$UNAME'" ;;
esac


INITDIR="$MOUNTDIR/pretest"
test -d "$INITDIR" \
	|| log "Pretest-Init dir ($INITDIR) doesn't exist. aborting."

##
## Add keys, if exist
##
HOMEDIR=~miles
if test -d "$INITDIR/keys" ; then
	log "adding SSH keys..."
	mkdir -p "$HOMEDIR/.ssh"
	find "$INITDIR/keys" -type f -print | xargs cat >> "$HOMEDIR/.ssh/authorized_keys"
	chown miles "$HOMEDIR/.ssh/authorized_keys"
	chmod 0600 "$HOMEDIR/.ssh/authorized_keys"
	log "adding SSH keys - done"
else
	log "no SSH keys found ($INITDIR/keys)."
fi

##
## Run Root scripts
##
if test -d "$INITDIR/rscripts" ; then
	log "Running root-scripts...."
	for i in $(find "$INITDIR/rscripts" -type f -name "*.sh" | sort) ;
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
if test -d "$INITDIR/scripts" ; then
	log "Running (non-root) scripts...."
	for i in $(find "$INITDIR/scripts" -type f -name "*.sh" | sort) ;
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
