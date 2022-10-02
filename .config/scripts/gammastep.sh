#!/usr/bin/env bash

function off(){
    echo "off"
    killall gammastep 1>/dev/null 2>/dev/null
		# kill -9 $(pgrep -x "gammastep");
}

function on(){
    off
    echo "on"
		exec gammastep -P -O ${GAMMASTEP_NIGHT:-3500}
}

pid=$(pgrep gammastep)

if [[ $1 = "on" ]]; then
  on
fi

if [[ $1 = "off" ]]; then
  off;
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
	echo "Nightlight is on"
else
	echo ""
	echo "Nightlight is off"
fi
