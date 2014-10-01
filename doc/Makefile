# Copyright 2014 (C) Assaf Gordon (assafgordon@gmail.com)
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.
#
SRC=pretest.texi

PDF=$(SRC:.texi=*.pdf)
HTML=$(SRC:.texi=*.html)
INFO=$(SRC:.texi=*.info)

all: $(HTML) $(PDF) $(INFO)

%.pdf: %.texi
	makeinfo --pdf $<

%.html: %.texi
	texi2any --set-customization-variable WORDS_IN_PAGE=0 \
	         --html --no-split \
	         -- $<

%.info: %.texi
	makeinfo $<
