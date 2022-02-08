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
bluetoothctl connect 50:97:1C:5F:44:D2 &
bluetoothctl connect D7:6A:25:A6:07:04 &

# powerprofilesctl set power-saver &
