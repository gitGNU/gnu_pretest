#!/bin/sh

# Copyright (C) 2015-2016 Assaf Gordon (assafgordon@gmail.com)
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

NAME=fedora25
ISO_URL=https://download.fedoraproject.org/pub/fedora/linux/releases/25/Server/x86_64/iso/Fedora-Server-dvd-x86_64-25-1.3.iso
ISO_FILE=$(basename "$ISO_URL")
INSECURE_DOWNLOAD=yes
QCOW2_SIZE=5G
RAM=768
QCOW2_FILE="$NAME.qcow2"

die() { BASE=$(basename "$0") ; echo "$BASE: error: $@" >&2 ; exit 1 ; }

## Create QCOW2 Image file
test -e "$QCOW2_FILE" \
    && die "qcow2 image file '$QCOW2_FILE' already exists. aborting"
qemu-img create -q -f qcow2 "$QCOW2_FILE" "$QCOW2_SIZE" \
        || die "failed to create qcow2 file '$QCOW2_FILE'"

## Download ISO (if not already downloaded)
if ! test -e "$ISO_FILE" ; then
    test "x$INSECURE_DOWNLOAD" = "xyes" \
        && INSECURE_PARAM=--no-check-certificate
    wget --quiet $INSECURE_PARAM -O "$ISO_FILE" "$ISO_URL" \
        || die "failed to download '$ISO_URL'"
fi

## Run KVM and install Fedora 25
##
## NOTE:
##   1. Fedora25 installation CD starts with a graphic screen,
##      "-curses" can not be used for initial installation.
##   2. Fedora25 installer requires 512MB of ram
kvm -name "$NAME" \
    -m "$RAM" \
    -net nic,model=virtio \
    -net user \
    -boot cd \
    -drive file="$QCOW2_FILE",if=virtio,media=disk,index=0 \
    -cdrom "$ISO_FILE" \
    -redir tcp:2222::22 \
    -vga cirrus \
    -serial mon:stdio

## vim: set shiftwidth=4:
## vim: set tabstop=4:
## vim: set expandtab:
