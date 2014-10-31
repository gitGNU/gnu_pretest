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
## This helper script connects to a running VM with a known
## SSH forwarded port, with options to bypass host checks
##

die() { BASE=$(basename "$0") ; echo "$BASE: error: $@" >&2 ; exit 1 ; }

PORT="$1"
test -z "$PORT" \
    && die "Missing TCP PORT parameter."
echo "$PORT" | grep -qE '^[0-9]+$' \
    || die "'$PORT' is not a valid TCP port number"
shift 1


ssh -o StrictHostKeyChecking=no \
    -o CheckHostIP=no \
    -o UserKnownHostsFile=/dev/null \
    -p "$PORT" \
    miles@localhost $@

## vim: set shiftwidth=4:
## vim: set tabstop=4:
## vim: set expandtab:
