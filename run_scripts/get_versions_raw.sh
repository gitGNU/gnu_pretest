printf AUTOCONF-VER: ; autoconf --version | head -n1 ;
printf AUTOMAKE-VER: ; automake --version | head -n1 ;
printf AUTOPOINT-VER: ; autopoint --version | head -n1 ;
if make --version 1>/dev/null 2>/dev/null ; then
  printf MAKE-VER: ; make --version | head -n1 ;
else
  echo MAKE-VER: non-gnu make
fi
printf GIT-VER: ; git --version | head -n1 ;
printf WGET-VER: ; wget --version | head -n1 ;
printf MAKEINFO-VER: ; makeinfo --version | head -n1 ;
printf CC-VER: ; cc --version | head -n1 ;
printf UNAME-S: ; uname -s || echo ;
printf UNAME-R: ; uname -r || echo ;
printf UNAME-M: ; uname -m || echo ;
printf UNAME-p: ; uname -p || echo ;
printf UNAME-i: ; uname -i || echo ;
printf UNAME-o: ; uname -o || echo ;
