#!/usr/bin/env bash

city=wrocław
appid=970606528befaa317698cc75083db8b2
temp=$(curl -s "https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$appid" | jq .main.temp)

sketchybar -m --set $NAME label="$city: $temp C , $(date '+%d.%m.%Y %H:%M')"
