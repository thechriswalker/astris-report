filename=project_astris
pdflatex_args=-synctex=1 -shell-escape -interaction=nonstopmode -file-line-error
luatex_args=--synctex=1 --shell-escape --interaction=nonstopmode --file-line-error

engine=pdflatex ${pdflatex_args}
#engine=luatex ${luatex_args}

.DEFAULT: final
.PHONY: final pdf clean library go-astris-ref dated

pdf: figures/astris-protocol.svg
	${engine} ${filename}

clean:
	find . -type f -regex '.*.\(acn\|acr\|alg\|aux\|lof\|log\|lot\|synctex.gz\|toc\|bbl\|blg\|glg\|glo\|gls\|glsdefs\|ist\|out\)' -delete

go-astris-ref:
	./get-go-astris-latest-commit.sh > content/99-go-astris.tex

figures/astris-protocol.svg: figures/astris-protocol.mmd
	mmdc --theme neutral --input figures/astris-protocol.mmd --output figures/astris-protocol.svg
	sed -i \
		-e 's/\"messageLine\([01]" stroke-width="2" stroke="\)none"/\"messageLine\1#333"/g' \
		-e 's/\(class=\"loopLine\"\)/\1 style="stroke-width:2px;stroke-dasharray:2,2;stroke:hsl\(0,0%,83%\);fill:hsl\(0,0%,83%\);"/g' \
		-e 's/\(class=\"labelBox\"\)/\1 style="stroke: hsl(0, 0%, 83%);fill: #eee;"/g' \
		figures/astris-protocol.svg

library:
	# the bibliography export from zotero contains wierd page references
	# which are not relevant
	@-${engine} ${filename}
	#sed -i '/^\s\+pages\? =/d' library.bib
	bibtex ${filename}

final: library figures/astris-protocol.svg go-astris-ref
	@-${engine} ${filename}
	# twice to ensure that the indexes are all built correctly
	makeglossaries ${filename}
	@-${engine} ${filename}
	${engine} ${filename}

dated: final
	cp ${filename}.pdf ${filename}_${shell date +%Y%m%d}_${shell git hash | head -c8}.pdf