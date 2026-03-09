#!/usr/bin/env bash
if xrandr | grep "eDP-1 connected" | grep -q " [0-9]\+x[0-9]\+"; then
    xrandr --output eDP-1 --off
else
    xrandr --output eDP-1 --auto
fi
