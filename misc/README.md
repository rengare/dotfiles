# misc

- `emoji.txt` — emoji plus search keywords, one per line, read by `bin/dot-emoji`.
  Generated from Omarchy's `shell/plugins/emojis/emojis.json` (MIT):

  ```fish
  jq -r '.[] | "\(.e) \(.k)"' path/to/omarchy/shell/plugins/emojis/emojis.json > misc/emoji.txt
  ```

- `zed_keymap`, `zed_settings` — Zed editor configuration.
