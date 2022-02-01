#!/bin/bash
sleep 1
nitrogen --restore &
#systemctl --user restart spotifyd.service &
insync start &
blueberry-tray &
# nm-applet --no-agent --indicator &
/usr/bin/spice-vdagent &
pactl unload-module module-raop-discover &
pactl load-module module-raop-discover &
bluetoothctl connect 50:97:1C:5F:44:D2 &
bluetoothctl connect 64:0B:D7:1A:86:90 &

powerprofilesctl set power-saver &
