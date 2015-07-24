#!/bin/sh

## Copyright (C) 2015 Assaf Gordon (assafgordon@gmail.com)
## License: GPLv3+

## This script reads the VM file sizes in doc/vm-sizes.txt
## and generates the Javascript file needed for the
## command-line generator web page.
##
##
## Typical usage:
##   cd <PRETEST>
##   vm-sizes-to-json.sh > tmp.js
## Then copy the content of 'tmp.js' into
## the '../pretest-website/pretest/vm-images.js' file.
##

awk 'BEGIN {
    FIRST=1
    comma = ""
    printf "var clean_install_vms = ["
}
/clean-install/ {
    if (FIRST) {
        FIRST=0
    } else {
        comma=","
    }

    n=split($1,a,".")
    id=a[1]

    printf comma "\n{ \"id\": \"" id "\", \"filename\": \"" $1 "\", \"comp_size:\": \"" $2 "\", \"raw_size\": \"" $3 "\"}" } END { print "\n];" }' doc/vm-sizes.txt

awk 'BEGIN {
    FIRST=1
    comma = ""
    printf "var build_ready_vms = ["
}
/build-ready/ {
    if (FIRST) {
        FIRST=0
    } else {
        comma=","
    }

    n=split($1,a,".")
    id=a[1]

    printf comma "\n{ \"id\": \"" id "\", \"filename\": \"" $1 "\", \"comp_size:\": \"" $2 "\", \"raw_size\": \"" $3 "\"}" } END { print "\n];" }' doc/vm-sizes.txt
