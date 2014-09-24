SRC=pretest.texi

PDF=$(SRC:.texi=*.pdf)
HTML=$(SRC:.texi=*.html)
INFO=$(SRC:.texi=*.info)

all: $(HTML) $(PDF) $(INFO)

%.pdf: %.texi
	makeinfo --pdf $<

%.html: %.texi
	makeinfo --html --no-split $<

%.info: %.texi
	makeinfo $<
