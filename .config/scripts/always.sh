$HOME/.config/scripts/bar.sh

echo $DESKTOP_SESSION
picture_path=$HOME/Sync/Pictures/background.png

xset -dpms
xset s noblank
xset s off -dpms

if [ "$DESKTOP_SESSION" == "sway" ]; then
  swaybg -i $picture_path &
fi

if [ "$DESKTOP_SESSION" == "hyprland" ]; then
  swaybg -i $picture_path &
fi

if [ "$DESKTOP_SESSION" == "i3" ]; then
  setxkbmap -layout pl
  loadkeys pl
  # for ibm model m
  # setxkbmap -option "caps:super" &
  # setxkbmap -option lv3:ralt_switch &
  # ============================================================
  
  killall greenclip
  greenclip clear &
  greenclip daemon &
  ~/.config/i3/scripts/switch_randr.sh &
  ~/.config/scripts/picom.sh &
  feh --bg-scale $picture_path &
  xset s off -dpms &
fi

autotiling &
blueman-applet &
$HOME/.config/scripts/gammastep.sh on
