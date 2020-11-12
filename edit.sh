#!/bin/sh

file=$1

if [ -n $DISPLAY ]; then
    # X
    if tty > /dev/null; then
        # terminal under X
        emacsclient -t $file || nano $file
    else
        # X with no terminal
        emacsclient -c $file || emacs $file || pluma $file
    fi
else
    # no X
    emacsclient -t $file || nano $file
fi
