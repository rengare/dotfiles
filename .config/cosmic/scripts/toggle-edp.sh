#!/usr/bin/env bash
# With an external display enabled, toggle the built-in display (eDP-1).
# Otherwise, toggle backlight between 0 and the last non-zero level (default 50%).
outputs=$(cosmic-randr list | sed 's/\x1b\[[0-9;]*m//g')

if grep -E '^[^ ].* \(enabled\)' <<<"$outputs" | grep -qv '^eDP-1 '; then
    if grep -q '^eDP-1 (enabled)' <<<"$outputs"; then
        cosmic-randr disable eDP-1
    else
        cosmic-randr enable eDP-1
    fi
    exit 0
fi

state="${XDG_STATE_HOME:-$HOME/.local/state}/cosmic-brightness"
current=$(brightnessctl get)
if [ "$current" -gt 0 ]; then
    mkdir -p "$(dirname "$state")"
    echo "$current" > "$state"
    brightnessctl -q set 0
else
    saved=$(cat "$state" 2>/dev/null)
    [ -n "$saved" ] || saved=$(( $(brightnessctl max) / 2 ))
    brightnessctl -q set "$saved"
fi
