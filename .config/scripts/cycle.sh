#!/bin/bash

# Find the currently focused workspace
focused_workspace=$(swaymsg -t get_workspaces | jq 'map(select(.focused))[0].name')
echo $focused_workspace

# Find the next window to focus on the current workspace
next_window=$(swaymsg -t get_tree | jq --arg focused_window "$focused_workspace" 'recurse(.nodes[]?) | select(.type=="con" and .focused==false ) | .id' | head -n 1) 

echo $next_window 

# Focus on the next window
if [ ! -z "$next_window" ]; then
    swaymsg "[con_id=$next_window]" focus
fi
