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

## This script starts a (previously-defined) libVirt pretest Domain,
## and waits until the booting is complete (or atleast until the guest gets
## an IP address and login with SSH is possible).
##
## The script also attemps to install the current user's SSH public key inside
## the guest.

die()
{
    BASE=$(basename -- "$0")
    echo "$BASE: error: $@" >&2
    exit 1
}

NAME="$1"
test -z "$NAME" && die "missing DOMAIN name"
NEWNAME=$(echo "$NAME" | tr -d -c '[:alnum:].\-_%^')
# ensure the name contains only 'simple' characters
test "x$NEWNAME" = "x$NAME" \
    || die "domain name '$NAME' contains disallowed characters; " \
           "Aborting to avoid potential troubles. " \
           "Please use only 'A-Za-z0-9.-_%^'."

domname=pretest-$NAME

##
## Until a better solution comes around...
##
VIRT_ADDR_SCRIPT=$(dirname -- "$0")/virt-addr
test -x "$VIRT_ADDR_SCRIPT" \
    || die "failed to find required script '$VIRT_ADDR_SCRIPT'"

##
## Check current state.
## If not 'running' - start it, and force later stages to allow retries.
##
retries=
state=$(virsh domstate -- "$domname") || die "virsh domstate failed"
if [ "x$state" != "xrunning" ] ; then
    virsh start -- "$domname" || die "virsh start '$domname' failed"
    sleep 2
    retries=yes
fi

##
## Get the domain's IP address
##
if [ "x$retries" = "xyes" ]; then
    attempts=20
    while true ; do
        domipaddr=$("$VIRT_ADDR_SCRIPT" -- "$domname" 2>/dev/null)
        test -n "$domipaddr" && break
        attempts=$((attempts-1))
        test $attempts -eq 0 \
            && die "failed to detect IP address for domain '$domname'"
        sleep 1
    done
else
    domipaddr=$("$VIRT_ADDR_SCRIPT" -- "$domname") \
        || die "failed to detect IP address for domain '$domname'"
fi

##
## Test connecting to port 22 (SSH)
##
if [ "x$retries" = "xyes" ]; then
    attempts=10
    while true ; do
        nc -- "$domipaddr" 22 </dev/null >/dev/null 2>/dev/null
        test $? -eq 0 && break
        attempts=$((attempts-1))
        test $attempts -eq 0 \
            && die "domain '$domname' with IP $domipaddr is not responding on TCP port 22"
        sleep 1
    done
else
    nc -- "$domipaddr" 22 </dev/null >/dev/null \
        || die "domain '$domname' with IP $domipaddr is not responding on TCP port 22"
fi

##
## Try to setup password-less login
## TODO:
##   This is too OpenSSH-specific. Fix it.
echo "Trying to copy your SSH public key into domain $domname."
echo "If prompted for password of user 'miles', please enter '12345':"
ssh-copy-id -o StrictHostKeyChecking=no \
            -o CheckHostIP=no \
            "miles@$domipaddr" \
        || die "failed to install/verify publish SSH key on '$domname' ($domipaddr)"
