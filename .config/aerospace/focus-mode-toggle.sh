#!/bin/sh
# $mod+space: sway's `focus mode_toggle` — jump between the floating and the
# tiled windows of the workspace. AeroSpace has no such command.

layout=$(aerospace list-windows --focused --format '%{window-layout}') || exit 0

if [ "$layout" = floating ]; then
    want='$2 != "floating"'
else
    want='$2 == "floating"'
fi

target=$(aerospace list-windows --workspace focused --format '%{window-id} %{window-layout}' \
    | awk "$want { print \$1; exit }")
[ -n "$target" ] && aerospace focus --window-id "$target"
