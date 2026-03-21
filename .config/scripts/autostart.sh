#!/bin/bash

if test -f "/home/ren/.sway"; then
  # Detect and launch the best available xdg-desktop-portal backend.
  # Priority: gnome → gtk → cosmic → wlr
  _portal_backend=""
  for _candidate in \
    /usr/lib/xdg-desktop-portal-gnome \
    /usr/libexec/xdg-desktop-portal-gnome \
    /usr/lib/xdg-desktop-portal-gtk \
    /usr/libexec/xdg-desktop-portal-gtk \
    /usr/lib/xdg-desktop-portal-cosmic \
    /usr/libexec/xdg-desktop-portal-cosmic \
    /usr/lib/xdg-desktop-portal-wlr \
    /usr/libexec/xdg-desktop-portal-wlr; do
    if test -x "$_candidate"; then
      _portal_backend="$_candidate"
      break
    fi
  done

  /usr/lib/xdg-desktop-portal -r &
  if test -n "$_portal_backend"; then
    "$_portal_backend" &
  fi
  unset _portal_backend _candidate

  echo "sway"
fi

if test -f "/home/ren/.i3"; then
  exec --no-startup-id /usr/libexec/xdg-desktop-portal-gtk &
  exec --no-startup-id /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
  exec --no-startup-id /usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg &
  xhost +si:localuser:ren
  dunst --config ~/.config/dunst/dunstrc &
  nm-applet --no-agent --indicator &
  echo "i3"
fi

bash /home/ren/.startup

sleep 1
