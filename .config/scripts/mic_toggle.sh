#!/bin/bash

if [ "$1" == "toggle" ]; then
    pactl set-source-mute @DEFAULT_SOURCE@ toggle
fi

if [ "$(pactl get-source-mute @DEFAULT_SOURCE@ | grep -c 'Mute: yes')" -eq 1 ]; then
    echo ""
else
    echo ""
fi
