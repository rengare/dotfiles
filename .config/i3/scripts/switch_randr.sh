ret=$(cat /sys/class/power_supply/AC/online)

if [[ $ret == "1" ]]; then
  autorandr monitor_only
else
  autorandr laptop
fi
