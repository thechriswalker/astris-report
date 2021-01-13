filename=project_astris

pdf:
	pdflatex -synctex=1 -interaction=nonstopmode ${filename}

clean:
	find . -type f -regex '.*.\(acn\|acr\|alg\|aux\|lof\|log\|lot\|synctex.gz\|toc\)' -delete

bib:
	# the bibliography export from zotero contains wierd page references
	# which are not relevant
	sed -i '/^\s\+pages\? =/d' library.bib
	bibtex ${filename}

final:
	# twice to ensure that the indexes are all built correctly
	pdflatex -synctex=1 -interaction=nonstopmode ${filename}
	bibtex ${filename}
	pdflatex -synctex=1 -interaction=nonstopmode ${filename}
	pdflatex -synctex=1 -interaction=nonstopmode ${filename}
	#	mv build/${filename}.pdf ${filename}_${shell date +%Y%m%d}.pdf
