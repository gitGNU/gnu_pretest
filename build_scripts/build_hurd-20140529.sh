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
## GNU Hurd/Debian setup is different than other OSes:
## we download a pre-built image, then extract it to a new image file,
## No installation ISO.
##

## See: https://people.debian.org/~sthibault/hurd-i386/README
##      http://www.gnu.org/software/hurd/hurd/running/qemu.html
NAME=hurd
IMG_URL=https://people.debian.org/~sthibault/hurd-i386/debian-hurd-20140529.img.gz
IMG_FILE=$(basename "$IMG_URL")
INSECURE_DOWNLOAD=yes
RAM=384
QCOW2_FILE="$NAME.qcow2"

die() { BASE=$(basename "$0") ; echo "$BASE: error: $@" >&2 ; exit 1 ; }

## Download Pre-built image (if not already downloaded)
if ! test -e "$IMG_FILE" ; then
    test "x$INSECURE_DOWNLOAD" = "xyes" \
        && INSECURE_PARAM=--no-check-certificate
    wget --quiet $INSECURE_PARAM -O "$IMG_FILE" "$IMG_URL" \
        || die "failed to download '$IMG_URL'"
fi

## Extract installation image to a new image (which will be modified)
test -e "$QCOW2_FILE" \
    && die "qcow2 image file '$QCOW2_FILE' already exists. aborting"
# Extract Hurd image (Raw format)
gunzip -dc < "$IMG_FILE" > "tmp-hurd.img" \
    || die "failed to extract '$IMG_FILE' to 'tmp-hurd.raw'"
# Convert to QCOW2
qemu-img convert -f raw "tmp-hurd.img" "$QCOW2_FILE" \
    || die "failed to convert RAW (tmp-hurd.img) to QCOW2 ($QCOW2_FILE)"
rm "tmp-hurd.img"

## Run KVM and Setup GNU-Hurd
##
## NOTE:
##   1. GNU-Hurd pre-built image can boot with "curses" mode,
##      easing copy&paste setup commands.
##   2. GNU-Hurd CAN'T use "virtio" disk/network - must use IDE/RTL8139
kvm -name "$NAME" \
    -m "$RAM" \
    -net nic,model=rtl8139 \
    -net user \
    -boot cd \
    -drive file="$QCOW2_FILE",media=disk,index=0 \
    -curses

## vim: set shiftwidth=4:
## vim: set tabstop=4:
## vim: set expandtab:
