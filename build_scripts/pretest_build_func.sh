##
## This script should be sourced, not executed
##
INSECURE_DOWNLOAD=yes

die() {
    BASE=$(basename "$0")
    echo "$BASE: error: $@" >&2
    exit 1
}

create_qcow2_image() {
    FILE="$1"
    SIZE="$2"

    test -z "$FILE" && die "missing FILE parameter"
    test -z "$SIZE" && die "missing SIZE parameter"

    test -e "$FILE" && die "qcow2 image file '$FILE' already exists. aborting"

    qemu-img create -q -f qcow2 "$FILE" "$SIZE" \
        || die "failed to create qcow2 file '$FILE'"
}

download_iso() {
    URL="$1"
    LOCALFILE="$2"

    test -z "$URL" && die "missing URL parameter"
    test -z "$LOCALFILE" && die "missing LOCALFILE parameter"

    test -e "$LOCALFILE" && return 0

    INSECURE_PARAM=
    if which wget>/dev/null 2>&1 ; then
        test "x$INSECURE_DOWNLOAD" = "xyes" \
            && INSECURE_PARAM=--no-check-certificate
        wget --quiet $INSECURE_PARAM -O "$LOCALFILE" "$URL" \
            || die "failed to download '$URL'"
        return 0
    fi

    if which curl>/dev/null 2>&1 ; then
        test "x$INSECURE_DOWNLOAD" = "xyes" && INSECURE_PARAM=--insecure
        curl --silent --show-error $INSECURE_PARAM -o "$LOCALFILE" "$URL" \
            || die "failed to download '$URL'"
        return 0
    fi

    die "neither wget or curl found. Can't download '$URL'"
}

## vim: set shiftwidth=4:
## vim: set tabstop=4:
## vim: set expandtab:
