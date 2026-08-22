#!/bin/bash

# Options for the menu
options="  Power Off\n  Reboot\n  Suspend\n  Lock\n  Logout"

# Show wofi menu
selected=$(echo -e "$options" | wofi --show dmenu --prompt="Power Menu" --width=250 --height=250)

case $selected in
*"Power Off"*)
  systemctl poweroff
  ;;
*"Reboot"*)
  systemctl reboot
  ;;
*"Suspend"*)
  systemctl suspend
  ;;
*"Lock"*)
  hyprlock || swaylock
  ;;
*"Logout"*)
  hyprctl dispatch exit
  ;;
esac
