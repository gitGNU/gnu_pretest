#!/bin/sh

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

