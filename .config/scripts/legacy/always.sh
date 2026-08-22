
echo $DESKTOP_SESSION
picture_path=$HOME/Sync/Pictures/background.png

xset -dpms
xset s noblank
xset s off -dpms

if test -f "/home/ren/.sway"; then
  swaybg -i $picture_path &
fi

if [ "$DESKTOP_SESSION" == "hyprland" ]; then
  swaybg -i $picture_path &
fi

if test -f "/home/ren/.i3"; then
  setxkbmap -layout pl
  loadkeys pl
  # map capslock to super 
  setxkbmap -option "caps:super" &
  # setxkbmap -option lv3:ralt_switch &
  # ============================================================
  
  # killall greenclip
  # greenclip clear &
  # greenclip daemon &
  ~/.config/i3/scripts/switch_randr.sh &
  ~/.config/scripts/picom.sh &
  # feh --bg-scale $picture_path &
  wal -i $picture_path & 
  wpg -s $picture_path $picture_path &
  # ~/.config/wpg/wp_init.sh &
  xset s off -dpms &

  # thinkpad x13 gen1
  xinput set-prop 12 "libinput Tapping Enabled" 1
  
fi

autotiling &
# blueman-applet &
~/.config/scripts/gammastep.sh on
~/.config/scripts/bar.sh
