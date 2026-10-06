#!/bin/sh
# $mod+d: rofi-style toggle for Raycast — hide it when it is up, open it when not.
# Raycast's own hotkey can't be set from the dotfiles, so AeroSpace binds this.

src="$HOME/.config/aerospace/raycast-toggle.swift"
bin="$HOME/.cache/aerospace/raycast-toggle"

# (re)build the helper when missing or older than its source
if [ ! -x "$bin" ] || [ "$src" -nt "$bin" ]; then
    mkdir -p "$(dirname "$bin")"
    swiftc -O -o "$bin" "$src" || exit 1
fi

"$bin" || open -a Raycast
