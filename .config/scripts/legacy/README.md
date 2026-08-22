# legacy

Scripts kept for reference but no longer wired into any session. Each was
unreferenced by every live config when it was moved here, and each has been
superseded:

| Script | Superseded by |
|---|---|
| `always.sh` | The sway config's own `exec`/`exec_always` block. Its `~/.sway` and `~/.i3` branches were already dead — neither marker file exists. |
| `bar.sh` | The generated `bar { }` block in `theme/current/sway.conf`. polybar-and-`wal` era. |
| `picom.sh` | Nothing: picom is an X11 compositor, and the X11 session is not in use. |
| `screenshot.sh` | `dot-capture` (`bin/dot-capture`). |
| `wofi-power-menu.sh` | `dot-menu` (`bin/dot-menu`); wofi is not installed. |

**Deliberately left in `.config/scripts/`** because a live config still calls
them, even though they look equally stale:

- `powermenu` — still bound in the i3, niri, hyprland and polybar configs. Only
  the sway binding was repointed at `dot-menu`.
- `gammastep.sh` — still referenced by `polybar/modules/gammastep.ini`. In sway,
  nightlight is `dotstyle toggle nightlight` instead.
- `mic_toggle.sh`, `weather.sh`, `power-profiles` — referenced by the polybar,
  waybar and sketchybar configs.
