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

virsh snapshot-revert --current "$domname" || die "virsh snapshot-revert failed"
virsh snapshot-delete --current "$domname" || die "virsh snapshot-delete failed"
virsh undefine "$domname" || die "virsh undefine failed"
