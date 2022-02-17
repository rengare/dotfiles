autotiling &

if [[ "$XDG_SESSION_TYPE" =~ "x11" ]]; then
    # ~/.config/polybar/launch.sh &
    ~/.config/i3/scripts/switch_randr.sh &
    ~/.config/i3/scripts/picom &
    nitrogen --restore &
    xset s off -dpms &
fi

gammastep -P -O 4500 &
