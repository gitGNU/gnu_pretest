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

set -e

DIR=$(mktemp -d)

for i in versions/*.txt ;
do
  NAME=$(basename "$i" .txt)
  cat "$i" \
    | cut -f2- -d: \
    | sed "1i$NAME" \
    | sed -r -e 's/	/ /g' -e 's/  */ /g' \
    | sed -e 's/^  *//' -e 's/  *$//' \
    | awk '{ if (length($0)==0) { print "N/A" } else { print $0 } }' \
    | sed -e 's/^autoconf (GNU Autoconf) //' \
          -e 's/^automake (GNU automake) //' \
          -e 's/^autoreconf (GNU Autoconf) //' \
          -e 's;^/usr/bin/autopoint (GNU gettext-tools) ;;' \
          -e 's;^/usr/pkg/bin/autopoint (GNU gettext-tools) ;;' \
          -e 's;^/usr/local/bin/autopoint (GNU gettext-tools) ;;' \
          -e 's/^makeinfo (GNU texinfo) //' \
          -e 's/^git version //' \
          -e '/^GNU Wget/{ s/^GNU Wget // ; s/ built on.*$// }' \
          -e '/rsync version/{
                 s/^rsync version // ;
                 s/protocol version [0-9]*$// }' > "$DIR/$NAME.prep"
done

cut -f1 -d: $(ls versions/*.txt |head -n1) \
  | sed -e 1ivm -e 's/-version$/ /'> "$DIR/fields"

paste $DIR/fields $DIR/*.prep > "$DIR/os-versions.tsv"

awk 'NR==1 || $1 !~ /^uname/' "$DIR/os-versions.tsv" > "$DIR/progs.tsv"
awk 'NR==1 || $1 ~  /^uname/' "$DIR/os-versions.tsv" > "$DIR/uname.tsv"

# leave empty to disable table transposing
TRANSPOSE=yes

test "x$TRANSPOSE" = "xyes" \
  && TRANSCMD="datamash transpose" \
  || TRANSCMD="cat"

OUTPUT="$DIR/os-versions.html"

echo "<html>
<head>
<title>PreTest - VM Versions</title>
<style>
table.osversions {
  white-space: nowrap;
  font-family: \"Courier New\", Courier, monospace;
  border-collapse: separate;
  border-spacing: 2.0ex 0.0ex;
}
table.osversions tr:nth-child(2n) {
  background: #F0F0F0;
}
table.osversions th {
  text-align: left;
}
</style>
</head>
<body>
<h1>PreTest - VM versions</h1>

<p>
PreTest's goal is to provide pre-built virtual-machine images of Free-Software
POSIX-compliant operating systems, ready for testing <b>autotools</b>-based programs.
</p>

<p>
Learn more at the PreTest Homepage: <a href=\"http://www.nongnu.org/pretest/\">http://www.nongnu.org/pretest/</a>
</p>

<br/>
<br/>
<br/>
<h2>Versions of installed programs on each VM:</h2>
" > "$OUTPUT"

cat "$DIR/progs.tsv" \
  | $TRANSCMD \
  | ./misc_scripts/htmlize.pl --skip-header --skip-footer >> "$OUTPUT"


echo "
<br/>
<br/>
<br/>
<h2>System Information (uname) on each VM:</h2>" >> "$OUTPUT"


cat "$DIR/uname.tsv" \
  | $TRANSCMD \
  | ./misc_scripts/htmlize.pl --skip-header --skip-footer >> "$OUTPUT"

echo "
</body>
</html>
" >> "$OUTPUT"

cp "$DIR/os-versions.html" "$DIR/os-versions.tsv" .
rm -rf "$DIR"
