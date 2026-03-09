#!/usr/bin/env bash
if swaymsg -t get_outputs | jq -e '.[] | select(.name == "eDP-1") | .active' | grep -q true; then
    swaymsg output eDP-1 disable
else
    swaymsg output eDP-1 enable
fi
