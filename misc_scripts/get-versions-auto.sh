#!/bin/sh

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

die()
{
BASE=$(basename "$0")
echo "$BASE: error: $@" >&2
exit 1
}

ssh-keygen -f "$HOME/.ssh/known_hosts" -R [localhost]:2222

sshpass -p "12345" \
    ssh -p 2222 -o StrictHostKeyChecking=no miles@localhost \
    'printf AUTOCONF-VER: ; autoconf --version | head -n1 ;
     printf AUTOMAKE-VER: ; automake --version | head -n1 ;
     printf AUTOPOINT-VER: ; autopoint --version | head -n1 ;
     printf MAKE-VER: ; make --version | head -n1 ;
     printf GIT-VER: ; git --version | head -n1 ;
     printf WGET-VER: ; wget --version | head -n1 ;
     printf MAKEINFO-VER: ; makeinfo --version | head -n1 ;
     printf CC-VER: ; cc --version | head -n1 ;
     printf UNAME-S: ; uname -s || echo ;
     printf UNAME-R: ; uname -r || echo ;
     printf UNAME-V: ; uname -v || echo ;
     printf UNAME-M: ; uname -m || echo ;
     printf UNAME-p: ; uname -p || echo ;
     printf UNAME-i: ; uname -i || echo ;
     printf UNAME-o: ; uname -o || echo ;'

