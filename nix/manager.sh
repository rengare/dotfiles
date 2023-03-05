#!/bin/bash
# check args if linux else if darwin

command="$HOME/.nix-profile/bin/home-manager switch  -b backup --extra-experimental-features nix-command --extra-experimental-features flakes --flake .#ren-$1"

if [ "$1" == "linux" ]; then
    echo "linux"
    $command
elif [ "$1" == "darwin" ]; then
    echo "darwin"
    $command
else
    echo "no args"
    exit 1
fi

echo "done"
