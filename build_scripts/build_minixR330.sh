#!/bin/sh

NAME=minixR330
ISO_URL=http://download.minix3.org/iso/minix_R3.3.0-588a35b.iso.bz2
INSECURE_DOWNLOAD=yes
QCOW2_SIZE=5G
RAM=384
ISO_FILE=$(basename "$ISO_URL" .bz2)
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
    wget --quiet $INSECURE_PARAM -O "$ISO_FILE.bz2" "$ISO_URL" \
        || die "failed to download '$ISO_URL'"
    bunzip2 "$ISO_FILE.bz2" || die "failed to decompress '$ISO_FILE.bz2'"
fi

## Run KVM and install Minix.
##
## NOTE:
##   1. During installation, must use IDE-based disk.
##      Afterwards changing to virtio is fine.
##   2. MINIX can boot with "curses" mode, easing copy&paste setup commands.
##   3. Login with 'root', no password.
kvm -name "$NAME" \
    -m "$RAM" \
    -net nic,model=virtio \
    -net user \
    -boot cd \
    -cdrom "$ISO_FILE" \
    -hda "$QCOW2_FILE" \
    -curses

## vim: set shiftwidth=4:
## vim: set tabstop=4:
## vim: set expandtab: