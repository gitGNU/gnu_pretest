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
## This helper scripts starts a PreTest QEMU Guest VM,
## automatically mounts a CDROM image with auto-run scripts,
## Then connects to it with SSH and run 'pretest-auto-build-check'.
##

port=4432

die() { BASE=$(basename "$0") ; echo "$BASE: error: $@" >&2 ; exit 1 ; }

##
## Check input file name
##
QCOW2_FILE="$1"
test -z "$QCOW2_FILE" \
    && die "missing QCOW2 filename (vm to use)"
BASE=$(basename "$QCOW2_FILE")
NAME=$(echo "$BASE" | tr -d -c '[:alnum:].\-_%^')
# ensure the name contains only 'simple' characters
test "x$BASE" = "x$NAME" \
    || die "image filename '$BASE' contains non-regular characters; " \
           "Aborting to avoid potential troubles. " \
           "Please use only 'A-Za-z0-9.-_%^'."
# Remove extension (e.g. '.qcow2')
NAME=${NAME%.*}

##
## Check Build package name
##
PACKAGE="$2"
test -z "$PACKAGE" \
    && die "missing PACKAGE to build (e.g. http://ftp.gnu.org/gnu/hello/hello-2.8.tar.gz)"
echo "$PACKAGE" | grep -qE "^(http|ftp|https|git)://" \
    || die "invalid PACKAGE source ($PACKAGE), expecting HTTP:// or FTP:// or GIT://"

##
## Run the image
##
./pretest-run.sh -p "$port" -z -r -i pretest-boot-msg.iso "$QCOW2_FILE" \
    die "failed to start VM image '$QCOW2_FILE'"

##
## Wait until the boot message appears on the serial file
## (sent from inside the VM when boot-sequence is done)
__count=1
while true ; do
    sleep 1
    __count=$((count+1))
    test "$__count" -gt 20 \
        && die "VM '$QCOW2_FILE' takes more than 20 seconds to boot. "\
                "perhaps it is stuck. Check PID file '$NAME.pid', " \
                "console boot '$NAME.console', or connect with ssh to " \
                " 'ssh -p $port miles@localhost'"
    test -e "$NAME.serial" || continue
    grep -q "^boot-done" "$NAME.serial" && break
done

##
## Login automatically
##
ssh -o StrictHostKeyChecking=no \
    -o CheckHostIP=no \
    -p "$port" \
    miles@localhost \
    pretest-auto-build-check "$PACKAGE"

rc=$?

if test "$rc" -eq 0 ; then
    pkill --uid "$(id -u)" --pidfile "$NAME.pid" "qemu"
    rm -f "$NAME.pid"
else
    echo "\
build of '$PACKAGE' failed on '$NAME' - leaving VM running.
connect with:
   pretest-ssh.sh $port
or kill it with:
   pkill -F $NAME.pid" >&2
    exit 1
fi


## vim: set shiftwidth=4:
## vim: set tabstop=4:
## vim: set expandtab:
