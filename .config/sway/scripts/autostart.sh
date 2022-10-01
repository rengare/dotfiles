#!/bin/bash

systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway

pkill -9 dunst && dunst --config ~/.config/dunst/dunstrc &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
# xss-lock -- /home/ren/.config/i3/scripts/blur-lock.sh &
sleep 1
cpupower frequency-set -u 1400 &
#insync start &
# blueberry-tray &
blueman-applet &
nm-applet --no-agent --indicator &
# /usr/bin/spice-vdagent &
# pactl unload-module module-raop-discover
# pactl load-module module-raop-discover
flatpak run md.obsidian.Obsidian &
flatpak run org.flameshot.Flameshot &

syncthing &
# xset -b &
rmmod pcspkr
