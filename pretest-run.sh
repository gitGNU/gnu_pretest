#!/bin/sh

# Copyright (C) 2014 Assaf Gordon (assafgordon@gmail.com)
#
# This file is part of PreTest
#
# PreTest is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# PreTest is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PreTest If not, see <http://www.gnu.org/licenses/>.

die() { BASE=$(basename "$0") ; echo "$BASE: error: $@" >&2 ; exit 1 ; }

show_help_and_exit() {
echo "HELP NOT ImPLEMENTED YET"
exit 1
}

## parse parameters
vga_default_driver=cirrus  # no way to change it from command-line, yet.
boot_from=cd
show_help=
ram_size=384
ssh_port=2222
snapshot=yes
pid_file=no
serial_file=no
curses=no
vga=no
daemonize=no
while getopts m:p:SrCDhzP name
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
        r)      serial_file=yes
                ;;
        C)      curses=yes
                ;;
        D)      vga=yes
                ;;
        h)      show_help=yes
                ;;
        z)      daemonize=yes
                pid_file=yes
                ;;
        P)      pid_file=yes
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
SERIALFILE="$NAME.serial"

## Prepare KVM parameters
SNAPSHOT_PARAM=
DAEMON_PARAM=
DISPLAY_PARAM=
PID_PARAM=
SERIAL_PARAM=
test "x$snapshot"    = xyes && SNAPSHOT_PARAM="-snapshot"
test "x$daemonize"   = xyes && DAEMON_PARAM="-daemonize"
test "x$pid_file"    = xyes && PID_PARAM="-pidfile '$PIDFILE'"
test "x$serial_file" = xyes && SERIAL_PARAM="-serial 'file:$SERIALFILE'"

# Figure out the display type.
# NOTE:
#  If PreTest VMs are configured to use the first serial as console.
#  If the user asked for Graphi display, send the first serial port to NULL.
#  (In the future, perhaps add "-serial stdio".)
#  This is needed in case the user asked for a serial file as well,
#  which should be connected to the SECOND serial port in the guest.
if test "x$curses" = xyes ; then
    DISPLAY_PARAM="-vga std -curses -serial null"
elif test "x$vga" = xyes ; then
    DISPLAY_PARAM="-vga $vga_default_driver -serial null"
else
    # Default: if display options specified, emulate '-no-graphics'

    #TODO: why is '-vga std' needed ? '-vga none' fails to boot some VMs...
    DISPLAY_PARAM="-nographic -serial mon:stdio"
fi

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
    $KVM_PARAMS


## vim: set shiftwidth=4:
## vim: set tabstop=4:
## vim: set expandtab:
