#!/bin/bash
flatpak run com.brave.Browser
exit

if ! command -v brave &> /dev/null
then
  firefox &
  exit
else
  brave &
  exit
fi

if ! command -v brave-browser  &> /dev/null
then
  firefox &
  exit
else
  brave-browser &
  exit
fi
