#!/bin/bash

if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    source "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.local/podman/bin"
export PATH="$PATH:$HOME/.nix-profile/bin"
export XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"
export XDG_DATA_DIRS="$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$XDG_DATA_DIRS"

export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1
export QT_QPA_PLATFORM=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export DESKTOP_SESSION=hyprland
export GDMSESSION=hyprland
export QT_QPA_PLATFORMTHEME=qt5ct

export BROWSER=zen-browser

xdg-settings set default-web-browser zen-browser.desktop
gio mime x-scheme-handler/http zen-browser.desktop
gio mime x-scheme-handler/https zen-browser.desktop

exec Hyprland
