#!/bin/sh

die() { BASE=$(basename "$0") ; echo "$BASE: error: $@" >&2 ; exit 1 ; }

show_help_and_exit() {
echo "HELP NOT ImPLEMENTED YET"
exit 1
}

## parse parameterse
boot_from=cd
show_help=
ram_size=384
ssh_port=2222
snapshot=yes
curses=no
display=no
nographic=yes
daemonize=no
while getopts zCDSm:p:h name
do
        case $name in
        m)      echo "$OPTARG" | grep -q '^[0-9][0-9]*$' \
                    || die "invalid RAM size '$OPTARG'"
                ram_size="OPT_ARG"
                ;;
        p)      echo "$OPTARG" | grep -q '^[0-9][0-9]*$' \
                    || die "invalid SSH redirection port '$OPTARG'"
                ssh_port="$OPTARG"
                ;;
        S)      snapshot=no
                ;;
        C)      curses=yes
                nographic=no
                ;;
        D)      display=yes
                nographic=no
                ;;
        h)      show_help=y
                ;;
        z)      daemonize=yes
                ;;
        ?)      die "Try -h for help."
        esac
done
[ ! -z "$show_help" ] && show_help_and_exit;

shift $((OPTIND-1))

## Check input file
QCOW2_FILE="$1"
test -z "$QCOW2_FILE" \
    && die "missing QCOW2 file name. See -h for more information"
test -e "$QCOW2_FILE" \
    || die "QCOW2 file '$QCOW2_FILE' not found"
qemu-img check "$QCOW2_FILE" \
    || die "file '$QCOW2_FILE' does not appear to be a valid QCOW2 image"

## Set names based on QCOW2 filename
NAME=$(basename "$QCOW2_FILE" | tr -d -c '[:alnum:].-_')
NAME=${NAME%.*}

PIDFILE="$NAME.pid"

## Prepare KVM parameters
SNAPSHOT_PARAM=
DAEMON_PARAM=
DISPLAY_PARAM=
PID_PARAM=
SERIAL_PARAM=
test "x$snapshot"  = xyes && SNAPSHOT_PARAM="-snapshot"
test "x$daemonize" = xyes && DAEMON_PARAM="-daemonize"
test "x$daemonize" = xyes && PID_PARAM="-pidfile '$PIDFILE'"
test "x$nographic" = xyes && DISPLAY_PARAM="-nographic"
test "x$curses"    = xyes && DISPLAY_PARAM="-curses"
test "x$display"   = xyes && DISPLAY_PARAM="-vga cirrus"
test "x$display"   = xyes && SERIAL_PARAM="-serial stdio"

## Ugly Hacks to accomodate some OSes
DISK_IF=virtio
NET_IF=virtio
KVM_PARAMS=

# Hack for GNU-Hurd: can't handle virtio
if echo "$NAME" | grep -q '[Hh]urd' ; then
    DISK_IF=ide
    NET_IF=rtl8139
fi
# Hack for NetBSD on older QEMUs: boot hangs.
# Seems related to this (but mentioned work-arounds don't work for me):
#  https://mail-index.netbsd.org/port-amd64/2013/02/19/msg001860.html
if echo "$NAME" | grep -qi 'netbsd' ; then
    # TODO: only disable on kvm < 2.0.0 (or specific CPUs?)
    KVM_PARAMS="-no-kvm"
fi
if echo "$NAME" | grep -qi 'dilos' ; then
    KVM_PARAMS="$KVM_PARAMS -machine pc-1.1"
fi

rm -f "$NAME.booted" "$NAME.par"

kvm -name "$NAME" \
    -drive file="$QCOW2_FILE",if=$DISK_IF,media=disk,index=0 \
    -m "$ram_size" \
    -net nic,model=$NET_IF \
    -net user \
    -boot "$boot_from" \
    -redir tcp:${ssh_port}::22 \
    -nodefaults \
    $PID_PARAM \
    $SNAPSHOT_PARAM \
    $DAEMON_PARAM \
    $DISPLAY_PARAM \
    $SERIAL_PARAM \
    $KVM_PARAMS \
    -vga std \
    -serial mon:stdio \
    -serial file:"$NAME.booted" \
    -serial file:"$NAME.par"

## vim: set shiftwidth=4:
## vim: set tabstop=4:
## vim: set expandtab:
