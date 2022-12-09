sketchybar                 \
--add item sound right     \
--set sound                \
update_freq=1              \
icon.font="Hack Nerd Font:Bold:17.0"  \
icon.color=0xffd08770      \
script="bash $PLUGIN_DIR/sound.sh" \
click_script="bash $PLUGIN_DIR/sound_click.sh"

sketchybar -m --add item mic right \
sketchybar -m --set mic update_freq=3 \
              --set mic script="bash $PLUGIN_DIR/mic.sh" \
              --set mic click_script="bash $PLUGIN_DIR/mic_click.sh"\
              icon.font="Hack Nerd Font:Bold:17.0"  

