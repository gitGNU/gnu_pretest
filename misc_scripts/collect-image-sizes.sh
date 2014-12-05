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


# A tiny script to generate './doc/sizes.txt' -
# listing the compressed/uncompressed size of each VM image file.

set -e

if test "$#" -eq 0 ; then
    echo "missing QCOW.XZ file names to check." >&2
    echo "example: $0 images-v0.1/trisquel7*.qcow2.xz" >&2
    exit 1
fi

for i
do
    test -e "$i" || { echo "warning: file '$i' not found" >&2 ; continue ; }
	BASE=$(basename "$i")
	XZSIZE=$(stat -c %s "$i" | numfmt --to=iec)
	UNXZSIZE=$(xz -dc -T2 < "$i" | wc -c | numfmt --to=iec)
    printf "%-35s %-5s %s\n" "$BASE" "$XZSIZE" "$UNXZSIZE"
done
