autotiling &
killall greenclip
greenclip clear &
greenclip daemon &

loadkeys pl
setxkbmap pl

~/.config/i3/scripts/switch_randr.sh &
~/.config/scripts/picom.sh &
feh ~/Pictures/background.png --bg-fill &
xset s off -dpms &

sleep 1

killall blueberry-tray &
blueberry-tray &

killall polybar 2>/dev/null
polybar 1>/dev/null &

$HOME/.config/scripts/gammastep.sh on

# $HOME/.config/polybar/launch.sh

# for ibm model m
setxkbmap -option "caps:super" &
setxkbmap -option lv3:ralt_switch &
# ============================================================

xset -dpms
xset s noblank
xset s off -dpms
