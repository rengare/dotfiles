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
}
