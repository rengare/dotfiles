if test -f "/home/ren/.i3"; then
  killall -q polybar

  sleep 1;
  source "${HOME}/.cache/wal/colors.sh"
  background=$color0
  foreground=$color7
  tertiary=$color2
  fourth=$color4

  polybar --reload monitor1 &
  polybar --reload monitor2 &
fi

if test -f "/home/ren/.sway"; then
  killall waybar 2>/dev/null
  waybar 1>/dev/null &
fi
