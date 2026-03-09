#!/usr/bin/env bash
# Toggle all non-builtin (external) outputs via xrandr
xrandr | grep " connected" | grep -v "^eDP-1 " | awk '{print $1}' | while read -r output; do
    if xrandr | grep "^$output " | grep -q " [0-9]\+x[0-9]\+"; then
        xrandr --output "$output" --off
    else
        xrandr --output "$output" --auto
    fi
done
