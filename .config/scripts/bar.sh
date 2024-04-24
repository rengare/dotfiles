if test -f "/home/ren/.i3"; then
  killall -q polybar

  sleep 1;
  source "${HOME}/.cache/wal/colors.sh"
  background=$color0
  foreground=$color7
  tertiary=$color2
  fourth=$color4

  if type "xrandr"; then
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
      MONITOR=$m polybar --reload main&
    done
  else
    polybar --reload main&
  fi
fi

if test -f "/home/ren/.sway"; then
  killall waybar 2>/dev/null
  waybar 1>/dev/null &
fi
