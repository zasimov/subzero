#!/bin/sh

if [ -z "$SCROLL" -o ! -f "$SCROLL" ]; then
    echo "no such scroll file"
    exit 1
fi

if [ -z "$SUBZERO_PORT" ]; then
    SUBZERO_PORT=5000
fi

echo "Run subzero on localhost:$SUBZERO_PORT"
echo "subzero scroll is $SCROLL"
subzero "$SCROLL" $SUBZERO_PORT &>/dev/null

