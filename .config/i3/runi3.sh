#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

if [ -f $HOME/.nix-profile/etc/profile.d/nix.sh ];
then
    source $HOME/.nix-profile/etc/profile.d/nix.sh
fi

export DESKTOP_SESSION=i3
export XDG_SESSION_DESKTOP=i3
export GDMSESSION=i3
export XDG_CURRENT_DESKTOP=i3
export QT_QPA_PLATFORMTHEME="qt5ct"
export XDG_DATA_DIRS="$HOME/.local/share:$HOME/.nix-profile/share:$XDG_DATA_DIRS"
export BROWSER=brave-browser

gio mime x-scheme-handler/http brave-browser.desktop
gio mime x-scheme-handler/https brave-browser.desktop

exec /usr/bin/i3
