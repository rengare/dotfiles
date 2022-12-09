#!/usr/bin/env sh

sketchybar --add item     calendar center              \
           --set calendar update_freq=15               \
                          icon.color=$BLACK            \
                          icon.font="$FONT:Black:12.0" \
                          icon.padding_left=15         \
                          label.width=220               \
                          label.align=right            \
                          label.color=$BLACK           \
                          label.padding_right=15       \
                          align=center                 \
                          script="$PLUGIN_DIR/time.sh" \
                          background.color=0xffb8c0e0  \
                          background.height=26         \
                          background.corner_radius=11
