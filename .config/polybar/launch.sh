#!/usr/bin/env bash

killall polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

polybar main -c $HOME/.config/polybar/config.ini &
