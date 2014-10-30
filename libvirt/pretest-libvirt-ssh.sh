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

## This script connects with SSH to a running libvirt pretest domain.

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
shift 1

domname=pretest-$NAME

##
## Until a better solution comes around...
##
VIRT_ADDR_SCRIPT=$(dirname -- "$0")/virt-addr
test -x "$VIRT_ADDR_SCRIPT" \
    || die "failed to find required script '$VIRT_ADDR_SCRIPT'"

##
## Check current state.
## If not 'running' - abort
##
retries=
state=$(virsh domstate -- "$domname") || die "virsh domstate failed"
test "x$state" = "xrunning" \
    || die "pretest domain '$domname' is not running." \
            "use pretest-libvirt-start.sh to start it."

##
## Get the domain's IP address
##
domipaddr=$("$VIRT_ADDR_SCRIPT" -- "$domname") \
    || die "failed to detect IP address for domain '$domname'"

##
## Test connection to TCP port 22
##
nc -- "$domipaddr" 22 </dev/null >/dev/null \
    || die "domain '$domname' with IP $domipaddr is not responding on TCP port 22"

##
## Connect to the domain
##
ssh -o StrictHostKeyChecking=no \
    -o CheckHostIP=no \
     "miles@$domipaddr" \
    $@
