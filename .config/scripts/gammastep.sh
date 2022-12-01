#!/usr/bin/bash

function off(){
    gammastep -P -O 5000 &
    killall gammastep 1>/dev/null 2>/dev/null
		# kill -9 $(pgrep -x "gammastep");
}

function on(){
    off
    echo "on"
		exec gammastep -P -O 3600 &
}

if [[ $1 = "on" ]]; then
  on
fi

if [[ $1 = "off" ]]; then
  off
fi

if [[ $1 = "toggle" ]]; then
	if pgrep -x "gammastep" > /dev/null; then
    off
	else
    on
	fi
fi

if pgrep -x "gammastep" > /dev/null; then
	echo ""
else
	echo ""
fi
