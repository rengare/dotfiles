#!/bin/bash

if [ -n "$(pgrep -x sway)" ]; then
  if [ -z "$(pgrep -x wshowkeys)" ]; then
    wshowkeys -a bottom -m 150 &
  else
    pkill -x wshowkeys
  fi
else
  if [ -z "$(pgrep -x screenkey)" ]; then
    screenkey -s small &
  else
    pkill -x screenkey 
  fi
fi
