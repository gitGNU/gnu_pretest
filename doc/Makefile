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
