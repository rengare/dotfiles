#!/bin/bash
kill -9 $(ps a | rofi -dmenu | awk "{ print $1 }")
