#!/usr/bin/bash

low=5400
high=5400

stateFile=~/.config/scripts/gammastep_state

function off() {
  if test -f "/home/ren/.sway"; then
    killall wlsunset 1>/dev/null 2>/dev/null
  fi

  if test -f "/home/ren/.i3"; then
    gammastep -P -O $high &
    killall gammastep 1>/dev/null 2>/dev/null
    # kill -9 $(pgrep -x "gammastep");
  fi
  echo off >$stateFile
}

function on() {
  off

  if test -f "/home/ren/.sway"; then
    exec wlsunset -T $high &
  fi

  if test -f "/home/ren/.i3"; then
    exec gammastep -P -O $low &
  fi

  echo on >$stateFile
}

if [[ $1 = "on" ]]; then
  on
fi

if [[ $1 = "off" ]]; then
  off
fi

if [[ $1 = "toggle" ]]; then

  if test -f "/home/ren/.sway"; then
    if pgrep -x "wlsunset" >/dev/null; then
      off
    else
      on
    fi
  fi

  if test -f "/home/ren/.i3"; then
    if pgrep -x "gammastep" >/dev/null; then
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
