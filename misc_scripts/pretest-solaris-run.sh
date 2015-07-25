#!/bin/sh

# Copyright (C) 2015 Assaf Gordon (assafgordon@gmail.com)
# License: GPLv3+

# Helper script for Solaris testing on opencsw.org.
# Run pretest-auto-check-build on few different hosts,
# then shows how to upload the results to the pretest server.

# NOTES:
# 1. default shell can't handle '$()' subshells - use backticks instead.
# 2. 'pretest-auto-build-check' has many '$()' statements -
#    so run it with bash (which exists on all hosts in /usr/bin/).

die()
{
	BASE=`basename "$0"`
	echo "$BASE: error: $@" >&2
	exit 1
}

test -z "$1" && die "missing TARBALL url to build"

DATE=`date +%F`
DIR=`mktemp -d $HOME/pretest.$DATE.XXXXXX` \
    || die "failed to create temp dir"

#
# Build the given tarball on the four hosts
#
for h in \
	unstable11x \
	unstable11s \
	unstable10x \
	unstable10s ;
do
	ssh $h -- \
		TMPDIR=$DIR nice /usr/bin/bash $HOME/pretest-auto-build-check "$1"
done

#
# once the four builds are over, search for the log tarball wit the results
#
echo "

The following are the results tarballs:

"
find "$DIR" -type f -name "*.pretest-build-report.tar.bz2"


#
# Suggest a way to upload them
#
echo "

To upload them, run:

"
URL="http://pretest-reports.housegordon.org/upload"
for f in `find "$DIR" -type f -name "*.pretest-build-report.tar.bz2"` ;
do
	echo "curl -F \"a=@$f\" \"$URL\""
done
