#!/bin/sh

NAME=openbsd55
ISO_URL=http://mirrors.nycbug.org/pub/OpenBSD/5.5/amd64/install55.iso
ISO_FILE=openbsd_$(basename "$ISO_URL")
INSECURE_DOWNLOAD=yes
QCOW2_SIZE=5G
RAM=384
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

## Run KVM and install OpenBSD-55
##
## NOTE:
##   1. OpenBSD installation can boot with "curses" mode,
##      easing copy&paste setup commands.
kvm -name "$NAME" \
    -m "$RAM" \
    -net nic,model=virtio \
    -net user \
    -boot cd \
    -drive file="$QCOW2_FILE",if=virtio,media=disk,index=0 \
    -cdrom "$ISO_FILE" \
    -curses

## vim: set shiftwidth=4:
## vim: set tabstop=4:
## vim: set expandtab:
