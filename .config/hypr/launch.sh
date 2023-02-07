#!/bin/bash

if [ -f $HOME/.nix-profile/etc/profile.d/nix.sh ];
then
    source $HOME/.nix-profile/etc/profile.d/nix.sh
fi

export PATH="$PATH:$HOME/.local/bin"
export XDG_DATA_DIRS="$HOME/.local/share:$HOME/.nix-profile/share:$XDG_DATA_DIRS"

export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1
export QT_QPA_PLATFORM=wayland
export XDG_CURRENT_DESKTOP=Sway
export XDG_SESSION_DESKTOP=sway
export DESKTOP_SESSION=Hyprland

exec Hyprland 
