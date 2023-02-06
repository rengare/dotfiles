$HOME/.config/scripts/bar.sh
$HOME/.config/scripts/gammastep.sh on

echo $DESKTOP_SESSION

xset -dpms
xset s noblank
xset s off -dpms

if [ "$DESKTOP_SESSION" == "sway" ]; then
  swaybg -i $HOME/Pictures/background.png &
fi

if [ "$DESKTOP_SESSION" == "hyprland" ]; then
  swaybg -i $HOME/Pictures/background.png &
fi

if [ "$DESKTOP_SESSION" == "i3" ]; then
  # for ibm model m
  setxkbmap -option "caps:super" &
  setxkbmap -option lv3:ralt_switch &
  # ============================================================
  
  setxkbmap pl
  loadkeys pl
  killall greenclip
  greenclip clear &
  greenclip daemon &
  ~/.config/i3/scripts/switch_randr.sh &
  ~/.config/scripts/picom.sh &
  feh ~/Pictures/background.png --bg-fill &
  xset s off -dpms &
fi

autotiling &
blueman-applet &
