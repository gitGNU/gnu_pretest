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

RAM=384
DISKTYPE=virtio
NETTYPE=virtio
GRAPHICS=none
CONNECT_URL=qemu:///system
OS_VARIANT=generic

die()
{
    BASE=$(basename -- "$0")
    echo "$BASE: error: $@" >&2
    exit 1
}

## Check input file
QCOW2_FILE="$1"
## Set names based on QCOW2 filename
BASE=$(basename -- "$QCOW2_FILE")
NAME=$(echo "$BASE" | tr -d -c '[:alnum:].\-_%^')
# ensure the name contains only 'simple' characters
test "x$BASE" = "x$NAME" \
    || die "image filename '$BASE' contains non-regular characters; " \
           "Aborting to avoid potential troubles. " \
           "Please use only 'A-Za-z0-9.-_%^'."
# Remove extension (e.g. '.qcow2')
NAME=${NAME%.*}

# Ensure the file exists, and is readable by QEMU
test -z "$QCOW2_FILE" \
    && die "missing QCOW2 file name. See -h for more information"
test -e "$QCOW2_FILE" \
    || die "QCOW2 file '$QCOW2_FILE' not found"

domname=pretest-$NAME

##
## Few Hacks for specific VMs
##

# Hack for GNU-Hurd: can't handle virtio
if echo "$NAME" | grep -qi 'hurd' ; then
    DISKTYPE=ide
    NETTYPE=rtl8139
    OS_VARIANT="msdos"
fi
if echo "$NAME" | grep -qi 'dilos' ; then
    GRAPHICS="vnc"
    RAM=768
    OS_VARIANT="opensolaris"
fi
if echo "$NAME" | grep -qi 'minix' ; then
    RAM=768
fi


tmp=$(mktemp -t pretest.XXXXXXX.xml) || die "failed to create tmp file"

virt-install --connect "$CONNECT_URL" \
    --name "$domname" \
    --ram $RAM \
    --vcpus=1 \
    --import \
    --print-xml \
    --os-variant=generic \
    --boot hd,cdrom \
    --disk "path=$QCOW2_FILE,device=disk,format=qcow2,bus=$DISKTYPE,perms=rw" \
    --graphics "$GRAPHICS" \
    --print-xml \
    --network "network=default,model=$NETTYPE" \
    --serial pty \
    --serial file,path="/tmp/$domname.serial"> "$tmp" \
    || die "virt-install failed"

virsh --connect "$CONNECT_URL" define "$tmp" \
    || die "virsh create failed"

snp=$(mktemp -t pretest-snap.XXXXXX.xml) \
    || die "failed to create tmp snapshot file"

echo "<domainsnapshot>
<name>clean-state</name>
</domainsnapshot>" > "$snp" || die "failed to write snapshot XML file ($smp)"

virsh --connect "$CONNECT_URL" snapshot-create "$domname" "$snp" \
    || die "virtsh snapshot-create failed"
