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
