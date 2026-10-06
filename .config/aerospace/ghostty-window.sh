#!/bin/sh
# $mod+Return: a new Ghostty window, like dot-terminal under sway.
# `open -na Ghostty` would start a second, separate Ghostty process every time;
# instead ask the running one over AppleScript (Ghostty.sdef has `new window`).
if pgrep -xq ghostty; then
    osascript -e 'tell application "Ghostty"' \
              -e 'new window' \
              -e 'activate' \
              -e 'end tell'
else
    open -a Ghostty
fi
