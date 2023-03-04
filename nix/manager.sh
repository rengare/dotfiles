#!/bin/bash
# check args if linux else if darwin

if [ "$1" == "linux" ]; then
  home-manager switch --flake .#ren-linux -b backup --extra-experimental-features nix-command
elif [ "$1" == "darwin" ]; then
  home-manager switch --flake .#ren-darwin -b backup --extra-experimental-features nix-command
else
    echo "no args"
    exit 1
fi

echo "done"
