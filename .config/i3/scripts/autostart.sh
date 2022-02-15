#!/bin/bash
dunst --config ~/.config/dunst/dunstrc &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
nitrogen --restore &
#systemctl --user restart spotifyd.service &
insync start &
blueman-applet &
# nm-applet --no-agent --indicator &
/usr/bin/spice-vdagent &
# pactl unload-module module-raop-discover
# pactl load-module module-raop-discover

xset -b &

