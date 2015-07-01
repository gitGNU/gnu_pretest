CSS=doc/pretest.css

all:
	@echo "nothing to do"

.PHONY: clean
clean:
	rm -rf web/

.PHONY: website
website: web/versions/index.html \
	 web/manual/index.html

os-versions.html:
	misc_scripts/build-os-versions-table.sh

web/versions/index.html: os-versions.html
	mkdir -p web/versions/
	cp os-versions.html web/versions/index.html

web/manual/index.html: doc/pretest.texi $(CSS)
	texi2any --set-customization-variable WORDS_IN_PAGE=0 \
	         --html --no-split \
	         --css-include="$(CSS)" \
	         --output "$@" \
	         -- "$<"
