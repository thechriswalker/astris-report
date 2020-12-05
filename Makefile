filename=project_astris

pdf:
	pdflatex -synctex=1 -interaction=nonstopmode ${filename}.tex

clean:
	find . -type f -regex '.*.\(aux\|lof\|log\|lot\|synctex.gz\|toc\)' -delete

final:
	# twice to ensure that the indexes are all built correctly
	pdflatex -aux-directory=temp -synctex=1 -interaction=nonstopmode ${filename}.tex
	pdflatex -aux-directory=temp -synctex=1 -interaction=nonstopmode ${filename}.tex
	#	mv build/${filename}.pdf ${filename}_${shell date +%Y%m%d}.pdf
