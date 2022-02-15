is_ac=$(cat /sys/class/power_supply/AC/online)

sleep 0.8

if [[ $is_ac == "1" ]]; then
  if [[ $XDG_SESSION_TYPE =~ "x11" ]];
    then
      autorandr monitor_only
    else
      wlr-randr --output eDP-1 --off 
  fi
else
  if [[ $XDG_SESSION_TYPE =~ "x11" ]];
    then
      autorandr laptop
    else
      wlr-randr --output eDP-1 --on
  fi
fi
