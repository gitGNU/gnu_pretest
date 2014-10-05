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

for i in $(find images -name "*.qcow2.xz" | sort);
do
	BASE=$(basename "$i")
	XZSIZE=$(stat -c %s "$i" | numfmt --to=iec)
	UNXZSIZE=$(xz -dc -T2 < "$i" | wc -c | numfmt --to=iec)
	printf "$BASE\t$XZSIZE\t$UNXZSIZE\n"
done
