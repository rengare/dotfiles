#!/bin/bash

if test -f "/home/ren/.sway"; then
  exec /usr/lib/xdg-desktop-portal -r &
  exec /usr/lib/xdg-desktop-portal-wlr &

  echo "sway"
fi

if [ "$DESKTOP_SESSION" == "hyprland" ]; then
  echo "hyprland"
fi

if test -f "/home/ren/.i3"; then
  /usr/lib/xdg-desktop-portal-gtk &
  /usr/bin/gnome-keyring-daemon --start --components=secrets &
  /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
  xhost +si:localuser:ren
  echo "i3"
 fi


if test barrier; then
  barrier &
fi

dunst --config ~/.config/dunst/dunstrc &
#xss-lock -- /home/ren/.config/i3/scripts/blur-lock.sh &

# cpupower frequency-set -u 1400 & 
nm-applet --no-agent --indicator &
xfce4-power-manager &
/usr/bin/spice-vdagent &
# pactl unload-module module-raop-discover
# pactl load-module module-raop-discover
#
sleep 1
# flatpak run md.obsidian.Obsidian &
# nohup easyeffects --gapplication-service &
nohup flatpak run com.github.wwmm.easyeffects --gapplication-service &

flatpak run com.nextcloud.desktopclient.nextcloud &
# nextcloud &
syncthing &
appimagelauncher.AppImage appimagelauncherd &

xset -b &
rmmod pcspkr &

flatpak run dev.lizardbyte.app.Sunshine &
