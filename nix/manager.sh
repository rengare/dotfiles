#!/bin/bash
# check args if linux else if darwin

echo "Generations before switch"
nix-env --list-generations

command="$HOME/.nix-profile/bin/home-manager switch  -b backup --extra-experimental-features nix-command --extra-experimental-features flakes --flake .#ren-$1"

if [ "$1" == "linux" ]; then
    $command
elif [ "$1" == "darwin" ]; then
    $command
elif [ "$1" == "linux-arm" ]; then
    $command
else
    echo "no args"
    exit 1
fi

# when https://github.com/NixOS/nixpkgs/issues/212158 is fixed, remove bellow
chmod +w -R ~/.local/share/omf 


echo "removing garbage"
nix-store --gc --print-roots | grep -v "/nix/store/" | xargs -r nix-store --delete
nix-store --gc

echo "done"

