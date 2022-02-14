bluetoothctl power on
~/.cargo/bin/i3-auto-layout &
~/.config/i3/scripts/switch_randr.sh &

if [[ "$XDG_SESSION_TYPE" =~ "x11" ]]; then
    nitrogen --restore
    xset s off -dpms &
    bash ~/.config/i3/scripts/picom &
fi

sh -c 'sleep 0.8; exec gammastep -P -O 4500'

bluetoothctl connect 50:97:1C:5F:44:D2
# bluetoothctl connect D7:6A:25:A6:07:04 &
