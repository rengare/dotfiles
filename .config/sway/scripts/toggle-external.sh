#!/usr/bin/env bash
# Toggle all non-builtin (external) outputs
swaymsg -t get_outputs | jq -r '.[] | select(.name != "eDP-1") | .name' | while read -r output; do
    if swaymsg -t get_outputs | jq -e --arg o "$output" '.[] | select(.name == $o) | .dpms' | grep -q true; then
        swaymsg output "$output" power off
    else
        swaymsg output "$output" power on
    fi
done
