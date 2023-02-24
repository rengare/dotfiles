#!/bin/bash

# Check which window manager is running
if [ -n "$(pgrep -x sway)" ]; then
  # Sway is running
  if [ -z "$(pgrep -x wshowkeys)" ]; then
    # wshowkeys is not running, so start it
    wshowkeys &
  else
    # wshowkeys is running, so kill it
    pkill -x wshowkeys
  fi
else
  # i3 is running
  if [ -z "$(pgrep -x showkey)" ]; then
    # showkey is not running, so start it
    showkey &
  else
    # showkey is running, so kill it
    pkill -x showkey
  fi
fi
