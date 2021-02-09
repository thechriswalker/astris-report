filename=project_astris
pdflatex_args=-synctex=1 -shell-escape -interaction=nonstopmode -file-line-error

.DEFAULT: all
.PHONY: all pdf clean library

pdf:
	pdflatex ${pdflatex_args} ${filename}

clean:
	find . -type f -regex '.*.\(acn\|acr\|alg\|aux\|lof\|log\|lot\|synctex.gz\|toc\)' -delete

library:
	# the bibliography export from zotero contains wierd page references
	# which are not relevant
	@-pdflatex ${pdflatex_args} ${filename}
	sed -i '/^\s\+pages\? =/d' library.bib
	bibtex ${filename}

final: library
	# twice to ensure that the indexes are all built correctly
	makeglossaries ${filename}
	pdflatex ${pdflatex_args} ${filename}
	pdflatex ${pdflatex_args} ${filename}
	#	mv build/${filename}.pdf ${filename}_${shell date +%Y%m%d}.pdf
