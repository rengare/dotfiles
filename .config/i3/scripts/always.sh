bluetoothctl power on
bluetoothctl connect 50:97:1C:5F:44:D2 &
xset s off -dpms &
powerprofilesctl set power-saver & 
~/.config/i3/scripts/switch_randr.sh &
~/.config/i3/scripts/picom &
~/.cargo/bin/i3-auto-layout &
sh -c 'sleep 1.8; exec gammastep -P -O 4500'

# bluetoothctl connect 50:97:1C:5F:44:D2 &
# bluetoothctl connect D7:6A:25:A6:07:04 &
