#!/usr/bin/env bash
if [[ $(niri msg --json outputs | jq -r '.["eDP-1"].current_mode == null') == "true" ]]; then
  niri msg output eDP-1 on
else
  niri msg output eDP-1 off
fi
