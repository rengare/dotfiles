#!/usr/bin/env bash
# Toggle the built-in display (eDP-1)
if hyprctl monitors -j | jq -e '.[] | select(.name == "eDP-1")' >/dev/null 2>&1; then
    hyprctl keyword monitor "eDP-1,disable"
else
    hyprctl keyword monitor "eDP-1,preferred,auto,1"
fi
