#!/bin/sh
#
city=wrocław

curl -s "https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=970606528befaa317698cc75083db8b2" | grep -oP '"temp":\K[^,]*' | awk '{printf("%dC", $1)}'
