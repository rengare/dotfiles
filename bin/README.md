# bin

Small scripts for the sway session, on `PATH` via `~/.local/bin` (linked by
`nix/linux/link.nix`). Modelled on Omarchy's `bin/`, scoped to what this session
actually needs.

The division of labour with [dotstyle](../tui/README.md): **scripts act,
dotstyle remembers and configures.** No script writes toggle state itself — it
calls `dotstyle toggle <name>`, so the script, the i3blocks indicator and the
TUI cannot disagree about whether something is on.

| Script | What it does |
|---|---|
| `dot-menu` | The nested rofi menu — Capture, Clipboard, Emoji, Toggles, System, Power. Bound to `$mod+$shift+d`. |
| `dot-capture` | `region\|screen\|window\|record\|text\|qr`. Stills to `~/Pictures` **and** the clipboard; OCR and QR results to the clipboard only. |
| `dot-osd` | Progress-bar OSD via dunst, stack-tagged so a held key replaces rather than stacks. |
| `dot-volume`, `dot-brightness` | The same `wpctl`/`brightnessctl` calls the bare keybindings made, plus the feedback they were missing. |
| `dot-lock` | swaylock using the generated `theme/current/swaylock.conf`, falling back to `loginctl lock-session` then `cosmic-greeter`. |
| `dot-session` | Starts/restarts the idle timer and clipboard watcher. Called by the sway include's single `exec_always`. |
| `dot-clipboard` | cliphist history through rofi. |
| `dot-emoji` | rofi over `misc/emoji.txt`, inserted with wtype. |
| `dot-notify` | One notification wrapper, so urgency and stack tags are spelled the same way everywhere. |
| `dot-launch-or-focus` | Raise a matching window via `swaymsg`, or launch it. |
| `dot-keys` | Searchable cheatsheet over the sway config's 81 bindings; selecting a row runs it. |
| `dot-kbd-backlight` | `up\|down\|cycle\|off\|restore` for `platform::kbd_backlight`, with OSD. |
| `dot-power` | cpufreq governor, TLP state and the battery charge cap. |
| `dot-screensaver` | `tte` effects fullscreen in foot; any key dismisses. Runs before the lock step. |
| `dot-window` | `bar\|opacity\|gaps` toggles over sway's IPC. |
| `dot-terminal-cwd` | New terminal in the focused terminal's directory, zellij included. |
| `dot-transcode` | ffmpeg wrappers: `shrink\|audio\|gif\|ascii`. |

## Design notes worth keeping

- **dunst is the OSD.** It is already running and already themed by dotstyle, so
  there is no second daemon and no second stylesheet. `-h int:value:N` draws the
  bar; `x-dunst-stack-tag` makes repeats replace.
- **Daemons are tracked by pidfile, not `pkill -f`.** A pattern like
  `wl-paste --watch cliphist` matches any command line *containing* those words,
  including a shell that happens to have them in its history expansion.
- **The idle timeline never passes through a shell.** `dotstyle idle args`
  prints one argument per line and `dot-session` reads them into an array, so
  `swaymsg 'output * power off'` stays a single argv entry. Sway's own config
  lexer strips quotes before `sh` sees them, which is why the timeline is not
  embedded in the sway include directly.
- **QR results go to the clipboard and nowhere else.** QR codes routinely carry
  `otpauth://` enrolment secrets and wifi passwords; printing one or putting it
  in a notification body would leak it to the journal and the notification
  history.
- **Every external tool is optional.** A missing binary produces a notification
  naming what to install, never a stack trace and never a broken session.
- **Window presence is asked of sway, not of the process table.** `dot-screensaver`
  checks `swaymsg -t get_tree` for its own `app_id`; the `pgrep -f app-id=...`
  it started as reported "already showing" whenever any command line happened
  to contain that string, including the shell that launched it.
- **`dot-screensaver` runs its payload under `bash`, and backgrounds the effect
  loop rather than the reader.** Both are load-bearing: `$SECONDS` and
  `read -n1 -s` are bash builtins that dash fails on, and POSIX reassigns a
  background command's stdin to `/dev/null`, so a backgrounded `read` sees EOF
  and dismisses the screensaver the instant it opens. `set -m` puts the loop in
  its own process group so dismissing it does not orphan `tte`.
- **Keyboard backlight needs the `input` group.** brightnessctl's udev rule
  grants `video` for display backlight but `input` for LEDs; being in one and
  not the other is easy to miss, so `dot-kbd-backlight` checks and says so.
- **Power state is read in the TUI but changed from the shell.** Setting the
  governor needs `pkexec` and the charge cap needs `sudo`; a password prompt
  over a full-screen TUI corrupts the display.
