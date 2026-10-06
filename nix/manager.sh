#!/bin/bash
# check args if linux else if darwin

# a non-login shell (e.g. ssh host 'bash manager.sh ...') has no nix on PATH
if ! command -v nix >/dev/null && [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

target="$1"
# ren-darwin is x86_64; on Apple Silicon it fails with "platform mismatch"
if [ "$target" == "darwin" ] && [ "$(uname -m)" == "arm64" ]; then
    target="darwin-arm"
fi

echo "Generations before switch"
nix-env --list-generations

command="$HOME/.nix-profile/bin/home-manager switch  -b backup --extra-experimental-features nix-command --extra-experimental-features flakes --flake .#ren-$target"

case "$target" in
    linux|darwin|linux-arm|darwin-arm) ;;
    *) echo "no args"; exit 1 ;;
esac

if ! $command; then
    echo "home-manager switch failed for ren-$target"
    exit 1
fi

# when https://github.com/NixOS/nixpkgs/issues/212158 is fixed, remove bellow
chmod -R +w ~/.local/share/omf


echo "removing garbage"
nix-store --gc --print-roots | grep -v "/nix/store/" | xargs -r nix-store --delete
nix-store --gc

echo "done"

