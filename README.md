# latex source for my dissertation

Makefile used to keep sources and build artifacts separate.

```
# build the pdf (only once so ToC may be not correct after clean)
make pdf

# build a final pdf (double build to ensure output correct)
make final

# clean all temp files
make clean
```

## build requirements

- `texlive texlive-latex-recommended texlive-latex-extra` probably more texlive packages...
- `inkscape` for the live svg > png conversion.
- `bibtex` if it is seperate...

I used VSCode to create this, with it's LaTeX Workshop plugin, although I did have to make it use my makefile
