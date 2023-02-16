#!/bin/bash

dunst --config ~/.config/dunst/dunstrc &
~/.config/scripts/polkit.sh
#xss-lock -- /home/ren/.config/i3/scripts/blur-lock.sh &

# cpupower frequency-set -u 1400 & 
nm-applet --no-agent --indicator &
/usr/bin/spice-vdagent &
# pactl unload-module module-raop-discover
# pactl load-module module-raop-discover
#
sleep 1
flatpak run md.obsidian.Obsidian &
flatpak run com.nextcloud.desktopclient.nextcloud &
syncthing &

xset -b &
rmmod pcspkr &

if [ "$DESKTOP_SESSION" == "sway" ]; then
  /usr/lib/xdg-desktop-portal &
  sleep 1
  echo "sway"
fi

if [ "$DESKTOP_SESSION" == "hyprland" ]; then
  echo "hyprland"
fi

if [ "$DESKTOP_SESSION" == "i3" ]; then
  echo "i3"
fi

