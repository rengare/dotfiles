#!/bin/sh

DESKTOP_SESSION=i3
export DESKTOP_SESSION=i3
export XDG_SESSION_DESKTOP=i3
export GDMSESSION=i3
export XDG_CURRENT_DESKTOP=i3
export QT_QPA_PLATFORMTHEME="qt5ct"
export BROWSER=brave-browser

export PATH=$PATH:/home/ren/.local/bin
export PATH=$PATH:/home/ren/.local/podman/bin
export PATH=$PATH:/home/ren/.nix-profile/bin
export PATH=$PATH:/home/ren/Applications
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CONFIG_DIRS="/etc/xdg"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"
export XDG_DATA_DIRS="$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$XDG_DATA_DIRS"

xdg-settings set default-web-browser brave-browser.desktop
gio mime x-scheme-handler/http brave-browser.desktop
gio mime x-scheme-handler/https brave-browser.desktop

if [ -f $HOME/.nix-profile/etc/profile.d/nix.sh ];
then
    source $HOME/.nix-profile/etc/profile.d/nix.sh
fi
# dbus-run-session -- sh -c "exec i3"
# exec dbus-launch /usr/bin/i3

~/.config/wpg/wp_init.sh
exec /usr/bin/i3
# startx /usr/bin/i3
