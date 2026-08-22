# dotstyle

Theme, font, wallpaper and window-manager look for these dotfiles, as a TUI.

The theming engine is modelled on [Omarchy](https://omarchy.org)'s — a theme is
a flat `colors.toml` of semantic color tokens, templates expand into generated
config files, and running apps are reloaded in place. The keybindings are not
Omarchy's; nothing here touches your sway bindings.

## Using it

```fish
cd ~/workspace/dotfiles/tui
cargo run                     # the TUI
cargo run -- list             # available themes, current one marked
cargo run -- apply gruvbox    # switch and reload, no TUI
cargo run -- render           # regenerate theme/current/ without touching the session
cargo run -- font "Iosevka" 15
cargo run -- show             # the resolved palette, one token per line

cargo run -- toggle list      # every toggle and whether it is on
cargo run -- toggle dnd       # flip do-not-disturb (on|off|toggle|status)
cargo run -- idle args        # swayidle arguments, one per line
cargo run -- get osd.timeout_ms   # read any setting by dotted path

cargo run -- keys             # the sway keybindings (dot-keys pipes this to rofi)
cargo run -- theme import ~/palette.toml    # convert an alacritty palette
cargo run -- theme install <git-url>        # clone a theme repo and apply it
cargo run -- theme new mine                 # scaffold from the current palette
cargo run -- theme remove mine
```

Install it on `$PATH` with `cargo install --path .`.

### Keys

`j`/`k` move, `h`/`l` switch tabs (and adjust values on the Look and System
tabs), `gg`/`G` jump to the ends, `Ctrl-d`/`Ctrl-u` scroll by half a page, `/`
filters (`esc` undoes, `⏎` accepts), `1`–`5` jump to a tab, `?` shows the keymap.

Five tabs: Themes, Font, Wallpaper, Look, System. **System** holds the toggles
and the idle timeline. Toggles there take effect immediately and are *not*
reverted on quit — flipping do-not-disturb is an action, not a pending edit;
the idle timings are settings and follow the normal preview/commit path.

**Wallpaper** previews the highlighted image in the right pane, using whatever
the terminal can actually draw. `ratatui-image` negotiates sixel / kitty /
iTerm2 by querying the terminal on startup, falls back to half-blocks where
there is no graphics protocol at all, and keeps ratatui's buffer in step with
the graphics either way — that last part is what makes emitting the escape
sequences by hand a bad idea, since the next redraw has to know they are there.
foot has sixel. `dotstyle graphics` reports what was negotiated, and the TUI
says so in the status line on open.

**Inside zellij the preview is half-blocks on purpose.** zellij answers the
capability query on the terminal's behalf and then re-renders the graphics
through its own grid, where they tear. It is singled out because
`ratatui-image` has explicit handling for tmux — it unwraps the passthrough —
and none for zellij, so the protocol negotiated there is one nothing downstream
honours. Run dotstyle in a bare foot window to get the real image.

`DOTSTYLE_GRAPHICS` overrides the decision: `off` forces half-blocks anywhere,
`on` queries the terminal even inside zellij — worth having, since zellij may
fix this and nothing here should be the reason you cannot find out.
`dotstyle graphics` reports what was chosen and why, and the TUI says the same
in its status line on open.

Two further things keep graphics from being disturbed. The pane is wiped only on
the first draw of a *new* picture, so whatever the previous one left outside the
new one's bounds gets written over: a graphics protocol paints over cells rather
than through them, and the terminal only drops an old image where a cell it
covered is written again. And the event loop no longer redraws four times a
second while idle — it waits for a key, except on the System tab, which reads
the battery and governor as it draws.

The resize filter is set to Lanczos rather than the crate's default of Nearest;
it costs nothing, since the resize happens on a size change rather than per
frame.

The preview is capped at **800x600 px** and centred in the pane. A pane on a
HiDPI display is several thousand pixels across, and letting a 4K wallpaper fill
it makes the pane the subject rather than the picture — besides handing the
terminal a few megabytes of sixel to re-encode whenever the image changes. The
cap is applied in cells, by dividing the pixel budget by the cell size; with no
known cell size the pane is left alone, since an uncapped preview beats one
clamped by a guess.

The caption reports the file's own dimensions, since what is on screen has been
resampled. Decoding is cached per file, so holding `j` through a pool of 4K
JPEGs still scrolls.

The wallpaper itself is **not** switched while you browse. swaybg has no
reload, so changing it means killing the old instance and starting a new one —
the desktop blanks for a beat, which is fine once on a deliberate change and
awful as a live preview. Only `⏎` puts the chosen image on screen.

Moving the cursor **applies the theme live** after a short pause. `⏎` writes
`theme/settings.toml` and *stays open* — it is a save point, not an exit, so
several changes can be kept in one visit. `q` reverts anything not yet saved
and quits; it is the only way out apart from Ctrl-C, which is the terminal's
own interrupt. Esc does nothing in normal mode, because a stray Esc that quit
would throw away work `⏎` had not yet kept.

## How it fits together

```
theme/themes/<name>/colors.toml  ─┐
theme/settings.toml              ─┼─→ render ─→ theme/current/*  ─→ reload
theme/templates/*.tpl            ─┘
```

`theme/current/` is generated and git-tracked: a theme switch leaves a working
tree diff you commit when you like the result. Nothing outside `theme/current/`
and `theme/settings.toml` is written by a theme switch — the tracked configs
each gained a single `include` line pointing into it, once.

| App | How it picks the theme up |
|---|---|
| sway | `include` near the top of `.config/sway/config` (gaps, borders, client colors, the whole `bar` block) |
| foot / alacritty / kitty | each config's native include/import, plus OSC sequences to retint windows already open |
| rofi | `@import` at the end of `config.rasi` |
| dunst | `dunstrc.d/50-dotstyle.conf` drop-in symlink |
| helix | `themes/dotstyle.toml` symlink; `config.toml` pins `theme = "dotstyle"` |
| btop | `~/.config/btop/themes/dotstyle.theme` symlink, wired automatically on apply |
| neovim | `lua/plugins/dotstyle.lua` loads the theme's colorscheme spec |
| fish | `conf.d/dotstyle.fish` sources the generated colors |
| GTK | `gsettings` color-scheme follows the theme's light/dark mode |
| swaylock | `theme/current/swaylock.conf`, read by `dot-lock` |

## Wallpapers

One shared pool, `~/Pictures/wallpapers` by default, set by `dir` under
`[wallpaper]` in `theme/settings.toml` (a leading `~` expands; a relative path
is taken against the dotfiles checkout). `dotstyle wallpaper dir` prints the
resolved path.

Wallpapers used to live inside each theme, in `theme/themes/*/backgrounds/`.
That coupling was wrong in both directions: it put ~53 MB of artwork in the
repo, and it silently threw away the picture you had chosen every time you
switched theme. The pool is independent of the theme — pick a wallpaper once
and it survives.

Drop any images you like in that directory; the Wallpaper tab lists whatever is
there, sorted. `settings.wallpaper.current` names one of them, and falls back to
the first in the pool when that file is gone — deleting a wallpaper outside
dotstyle leaves the desktop with a background rather than none.

`dotstyle wallpaper generate [theme]` derives one from a palette instead,
writing `<theme>-generated.png` into the pool; `--missing` covers only themes
with nothing generated yet, `--all` re-derives for every theme.

`dotstyle wallpaper apply` puts the chosen one on screen without touching the
rest of the theme. `dot-session` calls it at login — `dotstyle apply` restarts
swaybg whenever the wallpaper changes, but nothing re-applied it when sway
merely *started*, so a fresh login used to come up with no swaybg at all.

## Beyond theming

`theme/settings.toml` also holds the idle timeline, lock, OSD and battery
settings, and dotstyle owns the toggle state under `~/.local/state/dotstyle/`.
The scripts in [`bin/`](../bin/README.md) read both, so there is one source of
truth shared by the CLI, the bar indicators and the TUI.

## Adding a theme

`dotstyle theme import <alacritty.toml>` converts any alacritty palette — the
importer requires all eight `colors.normal` entries and rejects a file missing
any of them rather than emitting a half-built theme. `theme install <git-url>`
clones a theme repo, converting its `alacritty.toml` if it ships no
`colors.toml`. Both verify the result resolves to a complete palette and delete
the directory if it does not, so a broken theme never reaches the theme list.

Or by hand: drop a directory in `theme/themes/` with a `colors.toml`. Only the
colors you care about are required — `src/palette.rs` derives the rest (ANSI slots, bright
variants, selection, light/dark mode). Optionally add a `neovim.lua` returning a
lazy.nvim spec.

`cargo test` renders every theme through every template and fails if any token
goes unresolved, so a new theme is verified before it ever reaches the desktop.
`tests/imported_themes.rs` does the same for ten real alacritty palettes
recovered from this repo's own history — a broader test of the resolver than the
curated themes, which were all written to one house style.
