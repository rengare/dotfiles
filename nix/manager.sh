#!/bin/bash
# check args if linux else if darwin

if [ "$1" == "linux" ]; then
  home-manager switch --flake .#ren-linux -b backup
elif [ "$1" == "darwin" ]; then
  home-manager switch --flake .#ren-darwin -b backup
else
    echo "no args"
fi

echo "done"
