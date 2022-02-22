autotiling &
if [[ "$XDG_SESSION_TYPE" =~ "x11" ]]; then
    ~/.config/i3/scripts/switch_randr.sh &
    ~/.config/i3/scripts/picom &
    feh ~/Pictures/background.png --bg-fill &
    xset s off -dpms &
fi

sleep 1
gammastep -P -O 4500 &
