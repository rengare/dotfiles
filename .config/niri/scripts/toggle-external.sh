#!/usr/bin/env bash
# Toggle all non-builtin (external) outputs on niri
niri msg --json outputs | jq -r 'to_entries[] | select(.key != "eDP-1") | .key' | while read -r output; do
    if niri msg --json outputs | jq -e --arg o "$output" '.[$o].current_mode != null' > /dev/null; then
        niri msg output "$output" off
    else
        niri msg output "$output" on
    fi
done
