#!/bin/sh

# Copyright (C) 2017 Assaf Gordon (assafgordon@gmail.com)
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

# A tiny script to update './doc/sizes.txt'
# with the size of two new VM images (the clean-install and build-ready versions)

set -ue

test $# -gt 0 || { echo "missing VM id" >&2 ; exit 1 ; }

id="$1"

A=$(find images-v0.1-clean-install/ images-v0.2-build-ready/ \
    -name "*$1*" -type f | wc -l )
test "$A" -gt 0 || { echo "no VMs found for id '$id'" >&2 ; exit 1 ; }
test "$A" -eq 2 || { echo "wrong number of VMs found for id '$id' (found '$A' vms, expecting 2)" >&2 ; exit 1 ; }

tmp=$(mktemp -t pretest-vm-sizes.txt.XXXXXX)

cat doc/vm-sizes.txt > $tmp

find images-v0.1-clean-install/ images-v0.2-build-ready/ \
    -name "*$1*" -type f \
    | xargs misc_scripts/collect-image-sizes.sh >> $tmp

sort -k1V,1 -s -u $tmp > $tmp.sorted
mv $tmp.sorted doc/vm-sizes.txt
