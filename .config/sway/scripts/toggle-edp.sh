#!/usr/bin/env bash
# Toggle the built-in display (eDP-1).
#
# With external displays attached, disable/enable the output. With eDP-1 as
# the only output, disabling it would leave sway with no outputs at all (and
# on this machine a dead GPU can then never be woken), so blank it by dropping
# the backlight to 0 instead, remembering the old level for the next press.
state="${XDG_RUNTIME_DIR:-/tmp}/edp-brightness"

active=$(swaymsg -t get_outputs | jq -r '[.[] | select(.active)] | length')
edp_active=$(swaymsg -t get_outputs | jq -r '.[] | select(.name == "eDP-1") | .active')

if [[ $edp_active != true ]]; then
    swaymsg output eDP-1 enable
elif [[ -f $state ]]; then
    brightnessctl -q set "$(cat "$state")" && rm -f "$state"
elif ((active == 1)); then
    brightnessctl -m | cut -d, -f3 >"$state"
    brightnessctl -q set 0
else
    swaymsg output eDP-1 disable
fi
