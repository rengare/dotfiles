#!/bin/bash

nitrogen --restore &
systemctl --user restart spotifyd.service &
insync start &
blueberry-tray &
nm-applet --no-agent --indicator &
/usr/bin/spice-vdagent &

