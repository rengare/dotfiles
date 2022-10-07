#!/bin/bash
# kill -9 $(ps a | rofi -dmenu | awk "{ print $1 }")

COM=$(ps -a -u $USER --no-headers -o comm | sort | uniq -i | rofi -dmenu -p "   " -i)
killall -s KILL $COM
notify-send "$COM killed"
