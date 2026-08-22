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
| `dot-menu` | The nested rofi menu — Run, Capture, Clipboard, Emoji, Toggles, System, Power. Bound to `$mod+$shift+d`. |
| `dot-capture` | `region\|screen\|window\|record\|text\|qr`. Stills to `~/Pictures` **and** the clipboard; OCR and QR results to the clipboard only. |
| `dot-osd` | Progress-bar OSD via dunst, stack-tagged so a held key replaces rather than stacks. |
| `dot-volume`, `dot-brightness` | The same `wpctl`/`brightnessctl` calls the bare keybindings made, plus the feedback they were missing. |
| `dot-lock` | swaylock using the generated `theme/current/swaylock.conf`, falling back to `loginctl lock-session` then `cosmic-greeter`. |
| `dot-session` | Starts/restarts the idle timer and clipboard watcher. Called by the sway include's single `exec_always`. |
| `dot-bar` | The bar's `status_command`: i3blocks, restarted when it dies. Exits are logged to `$XDG_RUNTIME_DIR/dotstyle/bar.log`. |
| `dot-clipboard` | cliphist history through rofi. |
| `dot-emoji` | rofi over `misc/emoji.txt`, inserted with wtype. |
| `dot-notify` | One notification wrapper, so urgency and stack tags are spelled the same way everywhere. |
| `dot-launch-or-focus` | Raise a matching window via `swaymsg`, or launch it. |
| `dot-keys` | Searchable cheatsheet over the sway config's 81 bindings; selecting a row runs it. |
| `dot-run` | Every `dot-*` action, plus lock/suspend/log out/reboot/shut down, in one flat rofi list — type to filter, ⏎ to run. Also a rofi **script mode**, which is what puts these actions in `$mod+d` beside the apps. `--check` reports any script the list forgot. |
| `dot-kbd-backlight` | `up\|down\|cycle\|off\|restore` for `platform::kbd_backlight`, with OSD. |
| `dot-power` | cpufreq governor, TLP state and the battery charge cap. |
| `dot-screensaver` | `tte` effects fullscreen in foot; any key dismisses. Runs before the lock step. |
| `dot-window` | `bar\|opacity\|gaps` toggles over sway's IPC. |
| `dot-terminal-cwd` | New terminal in the focused terminal's directory, zellij included. |
| `dot-transcode` | ffmpeg wrappers: `shrink\|audio\|gif\|ascii`. |

## Two menus, on purpose

`dot-menu` is a tree and `dot-run` is a flat list, because they answer different
questions. Browsing — "what can this thing do?" — wants the tree. Knowing
already — "record a region" — wants one list and a filter, not four keystrokes
across three screens. `dot-run` is reachable from the top of `dot-menu`, so
neither needs a keybinding of its own.

`dot-run`'s table is written out rather than parsed from the scripts. Their
`usage:` lines are inconsistent enough that a parser would be guessing, and a
wrong guess is a menu entry that silently does nothing. `dot-run --check` guards
the failure that actually happens instead — a new script nobody listed — with an
explicit exemption list for the ones that are wrappers (`dot-notify`, `dot-osd`)
or need an argument (`dot-transcode`, `dot-launch-or-focus`).

Both dispatch through `swaymsg exec` rather than running the command directly:
rofi has exited by then, and a child of a dying shell inherits nothing useful.

`$mod+d` shows them too. It runs `rofi -show combi` rather than `-show drun`,
combining desktop entries with `dot-run` as a rofi **script mode** — declared as
`dot:dot-run` in `.config/rofi/config.rasi`. The key is unchanged; only what it
runs is. A script mode rather than generated `.desktop` files because those
would put thirty-odd session actions into every other launcher and application
menu on the system, not just this one.

## `status` is a read

`dotstyle toggle <name> status` used to fire the toggle's side effect along with
printing the state — so *reading* `nightlight` killed and restarted gammastep,
resetting the display gamma, and reading `stay-awake` restarted the session
daemons. Anything that drew a menu paid for it: `$mod+d` spent most of a second
churning processes and visibly flashed the screen before rofi appeared.

Two halves to the fix. `status` no longer acts (`toggles::is_mutating`); every
other verb still does, including `on` when it is already on, so a toggle
re-asserts state that may have drifted — gammastep can die without anyone
updating the marker file. And both menus now read all four states from one
`dotstyle toggle list` instead of four `status` calls.

## Keeping the bar alive

i3blocks dies across a suspend/resume cycle, and the bar then reads
`[error reading from status command]` until sway is restarted. Nothing recovers
on its own: sway spawns the status command once when it creates swaybar and
never notices it exited — `swaymsg reload` does not help either, because sway
only restarts swaybar when the *bar config* changed.

`dot-bar` supervises it. The awkward part is the i3bar protocol: a status
command emits one header line and then a single infinite JSON array, so a
second i3blocks cannot just be spliced in — its own header and its `[` would
land mid-stream. So `dot-bar` owns the header and the opening bracket, and each
i3blocks run contributes only array elements.

Two details make the difference between recovering and dying with it:

- **A lone `]` is dropped.** i3blocks closes the array on a clean shutdown.
  Forwarding that ends the stream for good — swaybar sees a complete array,
  stops reading, and every restart afterwards dies of SIGPIPE. The array
  belongs to `dot-bar` now, and `dot-bar` never ends it.
- **Lines are forwarded with `read`, not `cat`.** A process killed mid-write
  leaves a partial line; `cat` passes it on, swaybar sees malformed JSON and
  closes the pipe. `read` returns false on a line with no terminating newline,
  so the fragment is dropped.

Why i3blocks exits is still unknown. The exit status is written to
`$XDG_RUNTIME_DIR/dotstyle/bar.log` so the next occurrence says.

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
