#!/bin/bash

dunst --config ~/.config/dunst/dunstrc &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
xss-lock -- /home/ren/.config/i3/scripts/blur-lock.sh &
sleep 1
cpupower frequency-set -u 1400 & 
# nitrogen --restore &
#systemctl --user restart spotifyd.service &
#insync start &
blueberry-tray &
# blueman-applet &
nm-applet --no-agent --indicator &
/usr/bin/spice-vdagent &
# pactl unload-module module-raop-discover
# pactl load-module module-raop-discover
flatpak run md.obsidian.Obsidian &
syncthing &
xset -b &
rmmod pcspkr &
