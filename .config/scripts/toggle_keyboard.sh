#!/bin/bash

# Get current layout
current_layout=$(hyprctl devices | grep -A1 "Keyboard" | grep "active keymap" | awk '{print $3}')

if [ "$current_layout" == "English" ]; then
  # Switch to Polish
  hyprctl keyword input:kb_layout pl
  hyprctl keyword input:kb_options lv3:ralt_switch
  notify-send "Keyboard layout: Polish 🇵🇱"
else
  # Switch back to US
  hyprctl keyword input:kb_layout us
  hyprctl keyword input:kb_options
  notify-send "Keyboard layout: US 🇺🇸"
fi
