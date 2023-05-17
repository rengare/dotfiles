if test -f "/home/ren/.i3"; then
  killall polybar 2>/dev/null
  polybar 1>/dev/null &

fi

if test -f "/home/ren/.sway"; then
  killall waybar 2>/dev/null
  waybar 1>/dev/null &
fi
