#!/bin/bash
sleep 1
nitrogen --restore &
#systemctl --user restart spotifyd.service &
insync start &
blueman-applet &
# nm-applet --no-agent --indicator &
/usr/bin/spice-vdagent &
pactl unload-module module-raop-discover
pactl load-module module-raop-discover

dunst --config ~/.config/dunst/dunstrc
xset -b

