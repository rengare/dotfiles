autotiling &
killall greenclip
greenclip clear &
greenclip daemon &

if [[ "$XDG_SESSION_TYPE" =~ "x11" ]]; then
    ~/.config/i3/scripts/switch_randr.sh &
    ~/.config/i3/scripts/picom &
    feh ~/Pictures/background.png --bg-fill &
    xset s off -dpms &
fi

sleep 1

killall polybar 2>/dev/null
polybar 1>/dev/null &

$HOME/.config/scripts/gammastep.sh on

# $HOME/.config/polybar/launch.sh

# for ibm model m
setxkbmap -option "caps:super" &
setxkbmap -option lv3:ralt_switch &
# ============================================================


