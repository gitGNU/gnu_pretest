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

##
## Locally mount a PreTest VM QCOW2 image
##
VERSION=0.1
nbd_dev=/dev/nbd0

die()
{
    BASE=$(basename "$0")
    echo "$BASE: error: $@" >&2
    exit 1
}

show_help_and_exit()
{
    BASE=$(basename "$0")
echo "PreTest NBD Mount script (version $VERSION)
Copyright (C) 2014 Assaf Gordon (agn at gnu dot org)
License: GPLv3+

Usage:
$BASE [OPTIONS] FILE.QCOW2

Options:
-h      This help screen.

-d DEV  Use DEV as nbd device (default: $nbd_dev)

-m DIR  Use DIR as mounted directory.
        Default: create temporary directory in /tmp/ .

-W      Mount with write-access (default: mount read-only)
"
exit 0
}

## parse parameters
write_access=
mount_dir=
show_help=
while getopts d:m:Wh name
do
        case $name in
        m)      mount_dir="$OPTARG"
                test -d "$mount_dir" \
                    || die "mount directory ($mount_dir) is not a valid directory"
                ;;
        d)      nbd_dev="$OPTARG"
                ;;
        W)      write_access=yes
                ;;
        h)      show_help=yes
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


TESTID=$(id -u)
test "$TESTID" -eq 0 || die "this script requires sudo-powers."

QEMU_READONLY_PARAM=
MOUNT_READONLY_PARAM=
if test "x$write_access" = "xyes" ; then
    :
else
    QEMU_READONLY_PARAM="-r"
    MOUNT_READONLY_PARAM="-o ro"
fi

if test -z "$mount_dir" ; then
    mount_dir=$(mktemp -d -t pretest.XXXXXX) \
        || die "failed to create temporary directory"
fi

# Load the driver, if needed
if ! lsmod | grep -q nbd ; then
    modprobe nbd \
        || die "failed to load NBD kernel driver"
fi

## NBD-Connect the QCOW file to the NBD device
qemu-nbd $QEMU_READONLY_PARAM -c "$nbd_dev" "$QCOW2_FILE" \
    || die "qemu-nbd failed (device=$nbd_dev ; file=$QCOW2_FILE)"

## Notify the kernel to rescan partitions of connected devices
partprobe

## Tricky Part - How to tell which partition to mount?
## Highly dependant on the image type
#mount /dev/nbd0p1 "$mount_dir"

## vim: set shiftwidth=4:
## vim: set tabstop=4:
## vim: set expandtab:
