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

VERSION=0.1
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

die() { BASE=$(basename "$0") ; echo "$BASE: error: $@" >&2 ; exit 1 ; }

show_help_and_exit() {
BASE=$(basename "$0")
echo "PreTest Run Script version $VERSION
Copyright (C) 2014 Assaf Gordon (agn at gnu dot org)
License: GPLv3+

Usage:
$BASE [OPTIONS] FILE.QCOW2

Options:
-h      This help screen.

-m N    Use N MBs of ram (default $ram_size)

-p N    Forward guest VM's port 22 (SSH) to host port N (default $ssh_port)
        To connect to the guest, use the following on the host:
           ssh -p $ssh_port miles@localhost

-S      Disable QEMU's -snapshot mode, write changes to QCOW2 image file.
        (default: use -snapshot)

-r      Connect the guest VM's 2nd serial port to a file on the host.
        To send data from guest VM to host, run (inside the guest VM):
           echo hello > /dev/ttyS1 (on GNU/Linux)
           echo hello > /dev/com1  (on Hurd)
           echo hello > /dev/ttyu1 (on FreeBSD)
           echo hello > /dev/tty01 (on Dilos, MINIX, OpenBSD, NetBSD)
        The file will be named FILE.serial (based on input QCOW2 filename).

-C      Use CURSES VGA text interface (QEMU's -curses option).
        Default is no VGA adapter, only serial consoele.

-D      Use VGA Display mode (QEMU's -vga $vga_default_driver).
        Default is no VGA adapter, only serial consoele.

-z      Fork QMEU process in the background (QEMU's -daemonize).
        Default is to stay in the foreground. Implies -P .

-P      Write PID file (QEMU's -pidfile).
        The file will be named FILE.pid (based on input QCOW2 filename).

"
exit 1
}

## parse parameters
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
## Set names based on QCOW2 filename
BASE=$(basename "$QCOW2_FILE")
NAME=$(echo "$BASE" | tr -d -c '[:alnum:].\-_%^')
# ensure the name contains only 'simple' characters
test "x$BASE" = "x$NAME" \
    || die "image filename '$BASE' contains non-regular characters; " \
           "Aborting to avoid potential troubles. " \
           "Please use only 'A-Za-z0-9.-_%^'."
# Remove extension (e.g. '.qcow2')
NAME=${NAME%.*}

# Ensure the file exists, and is readable by QEMU
test -z "$QCOW2_FILE" \
    && die "missing QCOW2 file name. See -h for more information"
test -e "$QCOW2_FILE" \
    || die "QCOW2 file '$QCOW2_FILE' not found"
qemu-img check "$QCOW2_FILE" 1>/dev/null 2>&1 \
    || die "file '$QCOW2_FILE' does not appear to be a valid QCOW2 image"

## Prepare KVM parameters
PIDFILE="$NAME.pid"
SERIALFILE="$NAME.serial"
SNAPSHOT_PARAM=
DAEMON_PARAM=
DISPLAY_PARAM=
PID_PARAM=
SERIAL_PARAM=
test "x$snapshot"    = xyes && SNAPSHOT_PARAM="-snapshot"
test "x$daemonize"   = xyes && DAEMON_PARAM="-daemonize"
if test "x$pid_file"    = xyes ; then
    PID_PARAM="-pidfile $PIDFILE"
    rm -f "$PIDFILE"
fi
if test "x$serial_file" = xyes ; then
    SERIAL_PARAM="-serial file:$SERIALFILE"
    rm -f "$SERIALFILE"
fi

# Figure out the display type.
# NOTE:
#  If PreTest VMs are configured to use the first serial as console.
#  If the user asked for Graphic display, send the first serial port to NULL.
#  (In the future, perhaps add "-serial stdio".)
#  This is needed in case the user asked for a serial file as well,
#  which should be connected to the SECOND serial port in the guest.
if test "x$curses" = xyes ; then
    DISPLAY_PARAM="-vga std -curses -serial null"
elif test "x$vga" = xyes ; then
    DISPLAY_PARAM="-vga $vga_default_driver -serial null"
else
    # Default: if no display options specified, use only serial console
    DISPLAY_PARAM="-nographic"

    # If not forking into background, connect the serial port to the console
    test "x$daemonize"  != xyes \
        && DISPLAY_PARAM="$DISPLAY_PARAM -serial mon:stdio"
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
    # Disable KVM extension for NetBSD on kvm 1.x
    if kvm --version | head -n1 | grep -q '^QEMU emulator version 1\.' ; then
        KVM_PARAMS="-no-kvm"
    fi
fi
# Hack for DilOS: requires some machine configuraion
if echo "$NAME" | grep -qi 'dilos' ; then
    KVM_PARAMS="$KVM_PARAMS -machine pc-1.1"
fi
# Hack for MINIX, DilOS: require a VGA adapter (even if using
# serial console), otherwise won't boot.
if echo "$NAME" | grep -qi 'dilos\|minix' ; then
    # If the user requested a VGA adapter (either -C/curses or -D/cirrus),
    # then DISPLAY_PARAM will not contain 'nographic' and this is a no-op
    DISPLAY_PARAM=$(echo "$DISPLAY_PARAM" | sed 's/nographic/vga std -vnc none/')
fi

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
