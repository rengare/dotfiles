pkill -9 autotiling
autotiling &

~/.config/sway/scripts/gammastep.sh toggle &

pkill -9 swaybg 
swaybg -i ~/Pictures/background.png -m fill &

# for ibm model m
setxkbmap -option "caps:super" 
setxkbmap -option lv3:ralt_switch 
# ============================================================


