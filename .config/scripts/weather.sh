#!/bin/sh
#
city=wrocław
appid=970606528befaa317698cc75083db8b2
temp=$(curl -s "https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$appid" | jq .main.temp)

echo $city: $temp C
