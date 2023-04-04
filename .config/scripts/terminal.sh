#kitty

if [[ -f /opt/homebrew/bin/brew ]]; then
  /opt/homebrew/bin/wezterm start -- fish 
else 
  wezterm start -- fish
fi
