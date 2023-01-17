#!/bin/sh
export DESKTOP_SESSION=i3
export XDG_SESSION_DESKTOP=i3
export GDMSESSION=i3
export XDG_CURRENT_DESKTOP=i3
export QT_QPA_PLATFORMTHEME="qt5ct"
export XDG_DATA_DIRS=$XDG_DATA_DIRS:/home/*/.local/share/flatpak/exports/share

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

startx /usr/bin/i3 
