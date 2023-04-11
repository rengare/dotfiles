#!/usr/bin/bash

low=3800
high=4100

stateFile=~/.config/scripts/gammastep_state

function off(){
  if [ "$DESKTOP_SESSION" == "sway" ]; then
    killall wlsunset 1>/dev/null 2>/dev/null
  fi

  if [ "$DESKTOP_SESSION" == "i3" ]; then
      gammastep -P -O $high &
      killall gammastep 1>/dev/null 2>/dev/null
      # kill -9 $(pgrep -x "gammastep");
  fi
  echo off > $stateFile
}

function on(){
    off

    if [ "$DESKTOP_SESSION" == "sway" ]; then
      exec wlsunset -T $low &
    fi

    if [ "$DESKTOP_SESSION" == "i3" ]; then
      exec gammastep -P -O $low &
    fi

    echo on > $stateFile 
}

if [[ $1 = "on" ]]; then
  on
fi

if [[ $1 = "off" ]]; then
  off
fi

if [[ $1 = "toggle" ]]; then

  if [ "$DESKTOP_SESSION" == "sway" ]; then
    if pgrep -x "wlsunset" > /dev/null; then
      off
    else
      on
    fi
  fi

  if [ "$DESKTOP_SESSION" == "i3" ]; then
    if pgrep -x "gammastep" > /dev/null; then
      off
    else
      on
    fi
  fi
fi

state=$(cat $stateFile)


if [[ $state = "off" ]]; then
	echo ""
else
	echo ""
fi
