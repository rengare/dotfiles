#!/bin/bash

if test -f "/home/ren/.sway"; then
  exec /usr/lib/xdg-desktop-portal -r &
  exec /usr/lib/xdg-desktop-portal-wlr &

  echo "sway"
fi

if test -f "/home/ren/.i3"; then
  /usr/libexec/xdg-desktop-portal-gtk &
  /usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets &
  /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
  xhost +si:localuser:ren
  dunst --config ~/.config/dunst/dunstrc &
  nm-applet --no-agent --indicator &
  echo "i3"
fi

bash /home/ren/.startup

sleep 1
