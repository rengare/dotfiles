#kitty

if [[ -f /opt/homebrew/bin/brew ]]; then
  kitty
  # /opt/homebrew/bin/wezterm start -- fish 
else 
  wezterm start -- fish
fi
