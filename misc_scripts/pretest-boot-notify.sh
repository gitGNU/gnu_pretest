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
serial_device=


BASE=$(basename "$0")

die()
{
    echo "$BASE: error: $@" >&2
    exit 1
}

##
## Check whether file ($1) is a serial device
## (technically: any character-special file)
try_serial_device()
{
    __dev="$1"
    test -e "$__dev" || return 1
    test -c "$__dev" || return 1
    echo "serial-boot-test on device '$__dev'" > "$__dev" \
        || return 1
    serial_device="$__dev"
    return 0
}

##
## Write a message to the previously configured serial device file.
##
write_serial_message()
{
    test -z "$serial_device" && return 1
    echo "$@" > "$serial_device"
}

##
## Detect the device name of the second serial port
##
system_setup()
{
    UNAME=$(uname -s) || die "failed to get uname-s"
    case "$UNAME" in
        Linux)          try_serial_device "/dev/ttyS1"
                        ;;
        FreeBSD)        try_serial_device "/dev/ttyu1"
                        ;;
        NetBSD|OpenBSD) try_serial_device "/dev/tty01"
                        ;;
        SunOS)          try_serial_device "/dev/tty01"
                        ;;
        GNU)            try_serial_device "/dev/com1"
                        ;;
        Minix)          try_serial_device "/dev/tty01"
                        ;;
        *)              die "don't know which serial device to use " \
                            "for system '$UNAME'"
                        ;;
    esac

    test -z "$serial_device" && die "second serial device not found"
}

system_setup

write_serial_message "boot-done"

## vim: set shiftwidth=4:
## vim: set tabstop=4:
## vim: set expandtab:
