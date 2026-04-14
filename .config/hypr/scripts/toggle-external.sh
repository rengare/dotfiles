#!/usr/bin/env bash
# Toggle all non-builtin (external) outputs
hyprctl monitors -j | jq -r '.[] | select(.name != "eDP-1") | .name' | while read -r output; do
    if hyprctl monitors -j | jq -e --arg o "$output" '.[] | select(.name == $o)' >/dev/null 2>&1; then
        hyprctl keyword monitor "$output,disable"
    else
        hyprctl keyword monitor "$output,preferred,auto,1"
    fi
done
