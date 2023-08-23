if test -f "/home/ren/.i3"; then
  killall polybar 2>/dev/null

  polybar monitor1 1>/dev/null &
  polybar monitor2 1>/dev/null &

  # if type "xrandr"; then
  #   for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
  #     echo $m
  #     # MONITOR=$m polybar --reload &
  #   done
  # else
  #   polybar --reload &
  # fi

fi

if test -f "/home/ren/.sway"; then
  killall waybar 2>/dev/null
  waybar 1>/dev/null &
fi
