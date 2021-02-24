#!/bin/sh
REPO="https://github.com/thechriswalker/go-astris"
HASH=$(git ls-remote $REPO refs/heads/master | cut -f1 | head -c8)
echo "\\\def\\\astrisrepo{$REPO}"
echo "\\\def\\\astrishash{$HASH}"