filename=project_astris
pdflatex_args=-synctex=1 -shell-escape -interaction=nonstopmode -file-line-error

.DEFAULT: all
.PHONY: all pdf clean library go-astris-ref dated

pdf: figures/astris-protocol.svg
	pdflatex ${pdflatex_args} ${filename}

clean:
	find . -type f -regex '.*.\(acn\|acr\|alg\|aux\|lof\|log\|lot\|synctex.gz\|toc\|bbl\|blg\|glg\|glo\|gls\|glsdefs\|ist\|out\)' -delete

go-astris-ref:
	./get-go-astris-latest-commit.sh > content/99-go-astris.tex

figures/astris-protocol.svg: figures/astris-protocol.mmd
	mmdc --theme neutral --input figures/astris-protocol.mmd --output figures/astris-protocol.svg
	sed -i -e 's/\"messageLine\([01]" stroke-width="2" stroke="\)none"/\"messageLine\1#333"/g' figures/astris-protocol.svg

library:
	# the bibliography export from zotero contains wierd page references
	# which are not relevant
	@-pdflatex ${pdflatex_args} ${filename}
	#sed -i '/^\s\+pages\? =/d' library.bib
	bibtex ${filename}

final: library figures/astris-protocol.svg go-astris-ref
	@-pdflatex ${pdflatex_args} ${filename}
	# twice to ensure that the indexes are all built correctly
	makeglossaries ${filename}
	@-pdflatex ${pdflatex_args} ${filename}
	pdflatex ${pdflatex_args} ${filename}

dated: final
	cp ${filename}.pdf ${filename}_${shell date +%Y%m%d}_${shell git hash | head -c8}.pdf