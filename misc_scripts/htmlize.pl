#!/usr/bin/env perl
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
use strict;
use warnings;
use Getopt::Long;

my $skip_header;
my $skip_footer;

my $rc = GetOptions(
		"skip-header" => \$skip_header,
		"skip-footer" => \$skip_footer,
		) or die;

if (! $skip_header ) {
print<<'EOF';
<html>
<head>
<style>
table.osversions {
  white-space: nowrap;
  font-family: "Courier New", Courier, monospace;
}
table.osversions tr:nth-child(2n) {
  background: #F0F0F0;
}
</style>
</head>
<body>
EOF
}

print "<table class=\"osversions\">\n";

my $headers = <>;
if ($headers) {
	chomp $headers;
	my @fields = split /\t/, $headers;
	if (@fields) {
		print " <thead>\n";
		print "  <tr>\n";
		print join('', map{ "   <th>$_</th>\n" } @fields);
		print "  </tr>\n";
		print " </thead>\n";
	}
}

print " <tbody>\n";
while (my $line = <>) {
	chomp $line;
	my @fields = split /\t/, $line;
	print " <tr>\n";

	my $first = shift @fields;
	if ($first) {
		print "   <th>$first</th>\n";
	}

	if (@fields) {
		print join('', map{ "   <td>$_</td>\n" } @fields);
	}
	print " </tr>\n"
}

print " </tbody>\n";
print " </table>\n";

if (! $skip_footer) {
	print " </body>\n";
	print " </html>\n";
}

close STDOUT or die;
