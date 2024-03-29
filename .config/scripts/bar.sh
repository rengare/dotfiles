if test -f "/home/ren/.i3"; then
  killall -q polybar

  sleep 1;
  source "${HOME}/.cache/wal/colors.sh"
  background=$color0
  foreground=$color7
  tertiary=$color2
  fourth=$color4

  polybar --reload monitor1 --config=/home/ren/.config/polybar/config.ini &
  polybar --reload monitor2 --config=/home/ren/.config/polybar/config.ini &
fi

if test -f "/home/ren/.sway"; then
  killall waybar 2>/dev/null
  waybar 1>/dev/null &
fi
