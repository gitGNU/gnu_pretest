# Print versions of install programs and system information
#
####
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
####
# Usage example:
#   When a VM is running (and have port 22 redirected to port 2222),
#   use this script like so:
#     ssh -p 2222 miles@localhost < misc_scripts/get_versions.sh
#
for PROG in \
autoconf \
automake \
autopoint \
autoreconf \
make \
gmake \
makeinfo \
git \
wget \
rsync \
gcc \
cc \
;
do
  printf "${PROG}-version: " ;
  if which ${PROG} 1>/dev/null 2>/dev/null ; then
    if $PROG --version 1>/dev/null 2>/dev/null ; then
      $PROG --version | head -n1 ;
    else
      echo no-version
    fi ;
  else
    echo missing
  fi ;
done ;

for FLAG in -s -r -m -p -i -o -v ; do
  printf "uname$FLAG: " ;
  if uname $FLAG 2>/dev/null 1>/dev/null ; then
    uname $FLAG
  else
    echo
  fi ;
done ;
