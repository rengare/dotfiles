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

nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

. $HOME/.nix-profile/etc/profile.d/nix.sh
