#!/bin/bash

if ! command -v brave &> /dev/null
then
  firefox &
else
  brave-browser &
fi
