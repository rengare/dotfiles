#!/usr/bin/env bash

PICTURE=/tmp/i3lock.png
SCREENSHOT="scrot $PICTURE "

BLUR="5x4"

# $SCREENSHOT
# convert $PICTURE 
# convert $PICTURE -blur $BLUR $PICTURE
# i3lock -i $PICTURE
i3lock -B=5
# rm $PICTURE
