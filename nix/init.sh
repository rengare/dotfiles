#!/bin/bash

VER=$(cat ./ver);

echo $VER

if [[ "$1" == "linux" ]]; then
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
elif [[ "$1" == "darwin" ]]; then
  sh <(curl -L https://nixos.org/nix/install) 
else
  echo "Usage: $0 linux|darwin"
  exit 1
fi

. $HOME/.nix-profile/etc/profile.d/nix.sh

mkdir /nix/var/nix/profiles/per-user/$USER
mkdir /nix/var/nix/gcroots/per-user/$USER

nix-channel --add https://nixos.org/channels/nixos-$VER nixpkgs 
nix-channel --add https://github.com/nix-community/home-manager/archive/release-$VER.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

. $HOME/.nix-profile/etc/profile.d/nix.sh
