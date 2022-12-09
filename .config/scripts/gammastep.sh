#!/usr/bin/bash

stateFile=~/.config/scripts/gammastep_state

function off(){
    gammastep -P -O 5000 &
    killall gammastep 1>/dev/null 2>/dev/null
		# kill -9 $(pgrep -x "gammastep");
    echo off > $stateFile 
}

function on(){
    off
		exec gammastep -P -O 3600 &
    echo on > $stateFile 
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

state=$(cat $stateFile)

if [[ $state = "off" ]]; then
	echo ""
else
	echo ""
fi
