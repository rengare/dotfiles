{ config, pkgs, specialArgs, lib, ... }:
let
  # HID usage IDs: keyboard page 0x7, Caps Lock 0x39, Left Command 0xE3
  capsLock = "0x700000039";
  leftCommand = "0x7000000E3";
in {
  # Caps Lock acts as Cmd — the $mod of .config/aerospace, like Super on linux.
  # hidutil mappings are lost on reboot, so a login agent sets it each time.
  launchd.agents.capslock-to-cmd = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/hidutil"
        "property"
        "--set"
        ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":${capsLock},"HIDKeyboardModifierMappingDst":${leftCommand}}]}''
      ];
      RunAtLoad = true;
    };
  };

  # ⌘Space belongs to AeroSpace (sway's $mod+space), so drop Spotlight's
  # shortcut (symbolic hotkey 64) and apply it without logging out
  home.activation.disableSpotlightHotkey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
      '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

  # Zen uses Ctrl for its shortcuts like on linux (Ctrl-T, Ctrl-L, Ctrl-C...),
  # which also keeps them away from AeroSpace's ⌘ bindings. 17 = Control.
  # Pinned in user.js of every profile; Zen reads it at startup.
  home.activation.zenCtrlShortcuts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for profile in "$HOME/Library/Application Support/zen/Profiles"/*/; do
      [ -d "$profile" ] || continue
      userjs="$profile/user.js"
      if ! grep -qs '"ui.key.accelKey"' "$userjs"; then
        echo 'user_pref("ui.key.accelKey", 17);' >> "$userjs"
      fi
    done
  '';
}
