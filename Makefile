filename=project_astris
pdflatex_args=-synctex=1 -shell-escape -interaction=nonstopmode

svgs:
	inkscape

pdf:
	pdflatex ${pdflatex_args} ${filename}

clean:
	find . -type f -regex '.*.\(acn\|acr\|alg\|aux\|lof\|log\|lot\|synctex.gz\|toc\)' -delete

library.bib:
	# the bibliography export from zotero contains wierd page references
	# which are not relevant
	sed -i '/^\s\+pages\? =/d' library.bib
	bibtex ${filename}

final:
	# twice to ensure that the indexes are all built correctly
	pdflatex ${pdflatex_args} ${filename}
	sed -i '/^\s\+pages\? =/d' library.bib
	bibtex ${filename}
	makeglossaries ${filename}
	pdflatex ${pdflatex_args} ${filename}
	pdflatex ${pdflatex_args} ${filename}
	#	mv build/${filename}.pdf ${filename}_${shell date +%Y%m%d}.pdf
