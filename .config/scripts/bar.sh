if test -f "/home/ren/.i3"; then
  killall -q polybar

  sleep 1;
  source "${HOME}/.cache/wal/colors.sh"
  background=$color0
  foreground=$color7
  tertiary=$color2
  fourth=$color4

  if type "xrandr"; then
    # Check if monitors are duplicated
    primary_monitor=$(xrandr --query | grep " connected primary" | cut -d" " -f1)
    duplicated=false

    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
      if [ "$m" != "$primary_monitor" ]; then
        mode_primary=$(xrandr --query | grep "^$primary_monitor" -A1 | tail -n1 | cut -d" " -f4)
        mode_secondary=$(xrandr --query | grep "^$m" -A1 | tail -n1 | cut -d" " -f4)
        if [ "$mode_primary" == "$mode_secondary" ]; then
          duplicated=true
          break
        fi
      fi
    done

    if [ "$duplicated" = true ]; then
      MONITOR=$primary_monitor polybar --reload main&
    else
      for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        MONITOR=$m polybar --reload main&
      done
    fi
  else
    polybar --reload main&
  fi
fi

if test -f "/home/ren/.sway"; then
  killall waybar 2>/dev/null
  waybar 1>/dev/null &
fi
