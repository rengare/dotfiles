autotiling &
loadkeys pl
blueman-applet &

$HOME/.config/scripts/bar.sh
$HOME/.config/scripts/gammastep.sh on

xset -dpms
xset s noblank
xset s off -dpms

if [ "$DESKTOP_SESSION" == "sway" ]; then
  echo "sway"
  swaybg -i $HOME/Pictures/background.png &
else
  echo "i3"
  setxkbmap pl
  # for ibm model m
  setxkbmap -option "caps:super" &
  setxkbmap -option lv3:ralt_switch &
  # ============================================================
  killall greenclip
  greenclip clear &
  greenclip daemon &
  ~/.config/i3/scripts/switch_randr.sh &
  ~/.config/scripts/picom.sh &
  feh ~/Pictures/background.png --bg-fill &
  xset s off -dpms &
fi

