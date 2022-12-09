#!/usr/bin/env sh

sketchybar --add item battery right                      \
           --set battery script="bash $PLUGIN_DIR/battery.sh" \
                         update_freq=7.5                  \
           --subscribe battery system_woke


sketchybar -m --add event theme_changed AppleInterfaceThemeChangedNotification
