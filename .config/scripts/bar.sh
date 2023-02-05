if [ "$DESKTOP_SESSION" == "sway" ]; then
  killall waybar 2>/dev/null
  waybar 1>/dev/null &
else
  killall polybar 2>/dev/null
  polybar 1>/dev/null &
fi
