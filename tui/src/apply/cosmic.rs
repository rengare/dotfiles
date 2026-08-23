//! Repainting the COSMIC desktop from a dotstyle palette.
//!
//! COSMIC stores its look as `cosmic-config`: one directory per component,
//! one file per key, RON inside. Two of those directories matter here and the
//! difference between them is the whole reason this module is not a template:
//!
//! * `com.system76.CosmicTheme.Dark.Builder` holds the *inputs* — a background
//!   colour, an accent, a couple of tints. Sixteen small files.
//! * `com.system76.CosmicTheme.Dark` holds the *derived* theme — every button,
//!   container and divider state, a few hundred colours across three dozen
//!   files, none of which appear in the palette they came from.
//!
//! Every COSMIC application reads the second one. Nothing recomputes it: the
//! Builder is an input to `cosmic-settings`, not something the desktop watches.
//! Write only the Builder and the desktop does not change; write only the
//! derived theme and `cosmic-settings` shows stale inputs. So both are written,
//! and the derivation between them comes from `cosmic-theme` itself rather than
//! being reimplemented here — it is several hundred lines of Oklab stepping and
//! WCAG contrast search, and an approximation of it would be wrong in ways only
//! visible as slightly-off hover states.
//!
//! Most of the desktop then repaints itself: cosmic-comp, cosmic-panel and
//! the workspace and files applets watch the theme directory. A handful of
//! components do not, and have to be restarted — see `THEME_BLIND`.

use std::path::Path;

use anyhow::{Context, Result};
use cosmic_config::CosmicConfigEntry;
use cosmic_theme::{Theme, ThemeBuilder, ThemeMode};
use palette::Srgba;

use crate::color::parse_hex;
use crate::palette::Palette;
use crate::settings::Settings;

/// The libcosmic revision this was written against, kept here because the pin
/// in `Cargo.toml` is not a detail.
///
/// It has to match the libcosmic the *running* COSMIC was built against — on
/// this machine, whatever `cosmic-epoch/cosmic-settings/Cargo.lock` pins,
/// because the session is built and installed from that checkout. Two things
/// change across revisions and both fail silently:
///
/// * The config version, which is the directory name. Older libcosmic wrote
///   `com.system76.CosmicTheme.Dark/v1`, this one writes `v2`. A theme in the
///   wrong directory is not read, it is simply not there.
/// * The colour dialect. `(red: 0.4, green: 0.6, blue: 0.4, alpha: 1.0)`
///   became `"#689E6AFF"`, and a COSMIC on one side of that cannot parse the
///   other; it falls back to its stock theme without reporting anything.
///
/// So if a COSMIC upgrade stops taking dotstyle themes, check both: which
/// `v*` directory `~/.config/cosmic/com.system76.CosmicTheme.Dark/` has
/// content in, and what the colours inside look like.
///
/// Beware that `/usr/bin/cosmic-*` and `/usr/local/bin/cosmic-*` can be
/// different builds on the same machine. The session's binaries are the ones
/// that matter: `readlink -f /proc/$(pgrep -x cosmic-comp)/exe`.
pub const COMPATIBLE_REV: &str = "1f6dc991eaa5115a09be2505cc8a323e5b2b0bff";

/// Whether a COSMIC session is running.
///
/// The config is worth writing even when it is not — a theme chosen over ssh
/// or from a tty should be there at the next login — so this only decides how
/// the result is reported, never whether the write happens.
pub fn session() -> bool {
    std::env::var("XDG_CURRENT_DESKTOP")
        .is_ok_and(|desktop| desktop.split(':').any(|d| d.eq_ignore_ascii_case("COSMIC")))
}

/// Point COSMIC at `palette`.
pub fn apply(settings: &Settings, palette: &Palette) -> Result<Applied> {
    let dark = !palette.is_light();

    // Start from what is already on disk rather than from the stock theme.
    //
    // The Builder carries more than colour: corner radii, spacing, gaps, the
    // window-manager hint width, whether panels are frosted. Those are COSMIC's
    // own settings and dotstyle has no opinion about them, so clobbering them
    // with defaults would quietly undo whatever the user set in
    // cosmic-settings every time they changed theme.
    let builder_config = if dark {
        ThemeBuilder::dark_config()
    } else {
        ThemeBuilder::light_config()
    }
    .map_err(|error| anyhow::anyhow!("opening the COSMIC theme builder config: {error}"))?;

    let mut builder = match ThemeBuilder::get_entry(&builder_config) {
        Ok(builder) => builder,
        // Missing keys are the normal first-run case: the partial entry comes
        // back alongside the errors, already filled with defaults.
        Err((_errors, partial)) => partial,
    };

    tint(&mut builder, settings, palette);

    builder
        .write_entry(&builder_config)
        .map_err(|error| anyhow::anyhow!("writing the COSMIC theme builder: {error}"))?;

    let theme = builder.build();
    let name = theme.name.clone();

    let theme_config = if dark {
        Theme::dark_config()
    } else {
        Theme::light_config()
    }
    .map_err(|error| anyhow::anyhow!("opening the COSMIC theme config: {error}"))?;

    theme
        .write_entry(&theme_config)
        .map_err(|error| anyhow::anyhow!("writing the COSMIC theme: {error}"))?;

    mode(dark)?;

    Ok(Applied {
        name,
        restarted: refresh(),
    })
}

/// What `apply` did, for the caller to report.
pub struct Applied {
    pub name: String,
    pub restarted: Vec<&'static str>,
}

/// COSMIC components that read the theme once and never look again.
///
/// Most of the desktop watches the theme directory and repaints itself the
/// moment it changes — cosmic-comp, cosmic-panel, cosmic-workspaces and
/// cosmic-files-applet all hold an inotify watch on it. These do not. They
/// load the theme at startup and keep it for the life of the process, so a
/// launcher opened after a theme change still comes up in the old colours.
///
/// All four are supervised by cosmic-session, which restarts them within a
/// few seconds, so killing one is how you reload it. They are also all
/// transient UI — an overlay, a popup, a menu — so restarting is invisible
/// unless one happens to be on screen at that moment.
///
/// To check whether this list is still right:
///
/// ```text
/// for p in $(pgrep '^cosmic'); do
///   printf '%s ' "$(cat /proc/$p/comm)"
///   grep -ho 'ino:[0-9a-f]*' /proc/$p/fdinfo/* 2>/dev/null | sort -u | tr '\n' ' '
///   echo
/// done
/// ```
///
/// against the inode of `~/.config/cosmic/com.system76.CosmicTheme.Dark/v2`.
const THEME_BLIND: &[&str] = &[
    "cosmic-launcher",
    "cosmic-osd",
    "cosmic-app-library",
    "cosmic-notifications",
];

/// Restart the components that will not notice the new theme on their own.
///
/// Returns the ones that were actually running, so a session missing half of
/// them reports honestly instead of claiming four restarts.
fn refresh() -> Vec<&'static str> {
    if !session() {
        return Vec::new();
    }

    THEME_BLIND
        .iter()
        .copied()
        .filter(|component| {
            // Matched against the whole command line rather than the process
            // name, because `pkill` compares names through `comm`, which the
            // kernel truncates at 15 characters — "cosmic-app-library" and
            // "cosmic-notifications" are both longer and would never match.
            // Anchored so `cosmic-osd` cannot also match a `cosmic-osd-foo`.
            let pattern = format!("(^|/){component}$");
            std::process::Command::new("pkill")
                .arg("-f")
                .arg(&pattern)
                .stdout(std::process::Stdio::null())
                .stderr(std::process::Stdio::null())
                // pkill exits 0 when it signalled something, 1 when nothing
                // matched — which is the "not running" case, not an error.
                .status()
                .is_ok_and(|status| status.success())
        })
        .collect()
}

/// Overwrite the Builder's colours, and only its colours.
fn tint(builder: &mut ThemeBuilder, settings: &Settings, palette: &Palette) {
    let colour = |key: &str| palette.get(key).and_then(parse_hex).map(srgb);
    let first = |keys: &[&str]| keys.iter().find_map(|key| colour(key));

    // The palette variant, not the colours, is what `build()` reads to decide
    // `Theme.is_dark` — and every fallback in `ThemeBuilder::default()` is the
    // *dark* palette. So on a machine that has never had a light COSMIC theme,
    // reading the light Builder yields a dark palette, and a light dotstyle
    // theme would build a dark COSMIC theme into the light slot: light mode
    // selected, dark colours shown. Correct the variant before anything reads
    // it. High-contrast variants already answer `is_dark` correctly and are
    // left alone.
    let dark = !palette.is_light();
    if builder.palette.is_dark() != dark {
        builder.palette = if dark {
            ThemeBuilder::dark().palette
        } else {
            ThemeBuilder::light().palette
        };
    }

    // The palette's `name` becomes `Theme.name`, which is what cosmic-settings
    // shows in its theme list — so the desktop says "matte-black", not
    // "cosmic-dark".
    builder.palette.as_mut().name = settings.theme.clone();

    builder.bg_color = colour("background").map(opaque);

    // Containers sit a step off the background. dotstyle themes name that step
    // themselves, and using it keeps a COSMIC surface and a terminal pane the
    // same colour. `None` is a real answer, not a failure: cosmic-theme then
    // derives the surface by lightness stepping, which is what stock COSMIC
    // does.
    builder.primary_container_bg = first(&["lighter_background", "dark_background"]).map(opaque);
    builder.secondary_container_bg = None;

    builder.text_tint = colour("foreground");

    // The neutral ramp — dividers, disabled text, the grey furniture. `muted`
    // is the token meant for exactly this; `selection` is the next best thing
    // for a theme that does not define one.
    builder.neutral_tint = first(&["muted", "selection", "dark_foreground"]);

    builder.accent = colour("accent");
    builder.success = colour("green");
    builder.warning = colour("yellow");
    builder.destructive = colour("red");

    // The border drawn around the focused window. sway takes this from the
    // same token, so the two sessions agree about what "focused" looks like.
    builder.window_hint = first(&["accent"]);

    // Deliberately untouched: spacing, corner_radii, gaps, active_hint,
    // is_frosted. See `apply`.
}

/// Tell COSMIC which of the two themes to use.
///
/// Without this a dark dotstyle theme lands in the dark slot and is never
/// shown, because COSMIC is still displaying the light one.
fn mode(dark: bool) -> Result<()> {
    let config = ThemeMode::config()
        .map_err(|error| anyhow::anyhow!("opening the COSMIC theme mode config: {error}"))?;

    let mut mode = match ThemeMode::get_entry(&config) {
        Ok(mode) => mode,
        Err((_errors, partial)) => partial,
    };

    mode.is_dark = dark;

    // `auto_switch` flips `is_dark` by time of day, which would undo the line
    // above within the hour. A theme was just chosen explicitly, so the
    // schedule is no longer what the user meant.
    mode.auto_switch = false;

    mode.write_entry(&config)
        .map_err(|error| anyhow::anyhow!("writing the COSMIC theme mode: {error}"))
}

/// Put `image` on the COSMIC background.
///
/// COSMIC has no swaybg to restart: `cosmic-bg` watches its own config and
/// redraws. The existing entry is edited in place rather than rewritten,
/// because it carries choices dotstyle knows nothing about — rotation
/// frequency, sampling order, filter method.
///
/// Written as text rather than through `cosmic_config`, which would need
/// cosmic-bg's own `Entry` type to round-trip; a line edit needs no schema and
/// so cannot drop a field a newer cosmic-bg has added.
pub fn background(image: &Path, mode: &str) -> Result<()> {
    let directory = config_directory("com.system76.CosmicBackground")?;
    std::fs::create_dir_all(&directory)
        .with_context(|| format!("creating {}", directory.display()))?;

    let all = directory.join("all");
    let path = image.to_string_lossy();

    let entry = match std::fs::read_to_string(&all) {
        Ok(existing) => retarget(&existing, &path, mode),
        // No entry yet — the shape cosmic-bg expects, with everything but the
        // image left at its own defaults.
        Err(_) => format!(
            "(\n    output: \"all\",\n    source: Path(\"{path}\"),\n    \
             filter_by_theme: false,\n    rotation_frequency: 300,\n    \
             filter_method: Lanczos,\n    scaling_mode: {},\n    \
             sampling_method: Alphanumeric,\n)\n",
            scaling(mode)
        ),
    };

    write(&all, &entry)?;

    // Without this only the first display changes, and the others keep
    // whatever they had.
    write(&directory.join("same-on-all"), "true")?;
    Ok(())
}

/// `~/.config/cosmic/<id>/v1`, the layout every cosmic-config component uses.
fn config_directory(id: &str) -> Result<std::path::PathBuf> {
    let home = std::env::var_os("HOME").context("HOME is not set")?;
    Ok(Path::new(&home).join(".config/cosmic").join(id).join("v1"))
}

/// Replace through a temporary file, because cosmic-bg is watching: a
/// truncate-then-write is briefly an empty file, and an empty file is a parse
/// error that leaves the desktop with no wallpaper at all.
fn write(path: &Path, contents: &str) -> Result<()> {
    let staging = path.with_extension(format!("tmp{}", std::process::id()));
    std::fs::write(&staging, contents).with_context(|| format!("writing {}", staging.display()))?;
    std::fs::rename(&staging, path)
        .with_context(|| format!("moving into place: {}", path.display()))?;
    Ok(())
}

/// Replace the `source:` and `scaling_mode:` of an existing entry, leaving the
/// rest of the RON alone.
///
/// `filter_by_theme` is forced off with them: it makes cosmic-bg choose its
/// own wallpaper to suit the light/dark mode, which is a different feature
/// competing for the same slot — leave it on and the image chosen here is
/// replaced the moment the mode changes.
fn retarget(entry: &str, path: &str, mode: &str) -> String {
    let mut out = String::with_capacity(entry.len() + path.len());

    for line in entry.lines() {
        let indent: String = line.chars().take_while(|c| c.is_whitespace()).collect();
        let trimmed = line.trim_start();

        if trimmed.starts_with("source:") {
            out.push_str(&format!("{indent}source: Path(\"{path}\"),\n"));
        } else if trimmed.starts_with("scaling_mode:") {
            out.push_str(&format!("{indent}scaling_mode: {},\n", scaling(mode)));
        } else if trimmed.starts_with("filter_by_theme:") {
            out.push_str(&format!("{indent}filter_by_theme: false,\n"));
        } else {
            out.push_str(line);
            out.push('\n');
        }
    }

    out
}

/// A swaybg mode as cosmic-bg spells it.
///
/// cosmic-bg has no tile, and its `Fit` takes a fill colour; both fall back to
/// `Zoom`, which is the mode almost every wallpaper wants anyway.
fn scaling(mode: &str) -> &'static str {
    match mode {
        "stretch" => "Stretch",
        "fit" | "center" => "Fit((0.0, 0.0, 0.0))",
        _ => "Zoom",
    }
}

fn srgb((r, g, b): (u8, u8, u8)) -> palette::Srgb {
    palette::Srgb::new(r, g, b).into_format()
}

fn opaque(colour: palette::Srgb) -> Srgba {
    Srgba::new(colour.red, colour.green, colour.blue, 1.0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn retargeting_keeps_the_settings_it_does_not_own() {
        let entry = "(\n    output: \"all\",\n    \
                     source: Path(\"/old/one.jpg\"),\n    \
                     filter_by_theme: true,\n    \
                     rotation_frequency: 900,\n    \
                     filter_method: Lanczos,\n    \
                     scaling_mode: Stretch,\n    \
                     sampling_method: Alphanumeric,\n)";

        let out = retarget(entry, "/new/two.png", "fill");

        assert!(out.contains("source: Path(\"/new/two.png\"),"));
        assert!(out.contains("scaling_mode: Zoom,"));
        assert!(out.contains("filter_by_theme: false,"));
        // Untouched, and still indented the way it was.
        assert!(out.contains("    rotation_frequency: 900,"));
        assert!(out.contains("    sampling_method: Alphanumeric,"));
        assert!(!out.contains("/old/one.jpg"));
    }

    /// The two things that make a written theme invisible rather than wrong.
    ///
    /// Both are properties of the pinned libcosmic, so this is really a check
    /// that the pin has not drifted from the COSMIC it has to talk to.
    #[test]
    fn the_theme_is_written_where_and_how_cosmic_reads_it() {
        assert_eq!(
            Theme::VERSION,
            2,
            "the config version is the directory name; a theme in the wrong \
             v* directory is simply not found"
        );

        let theme = ThemeBuilder::dark().build();
        let rendered =
            ron::ser::to_string_pretty(&theme.accent, ron::ser::PrettyConfig::new()).unwrap();

        assert!(
            rendered.contains("base: \"#"),
            "expected hex colours like `base: \"#63D0DFFF\"`, got:\n{rendered}\n\
             libcosmic has changed dialect; see COMPATIBLE_REV ({COMPATIBLE_REV})"
        );
    }

    /// A palette built the way the real thing is: written out, loaded, and
    /// run through the resolver, so the tokens `tint` reaches for are the
    /// ones a theme actually ends up with.
    fn palette(colors: &str, tag: &str) -> Palette {
        let dir = std::env::temp_dir().join(format!(
            "dotstyle-cosmic-{tag}-{}-{:?}",
            std::process::id(),
            std::thread::current().id()
        ));
        std::fs::create_dir_all(&dir).unwrap();
        let file = dir.join("colors.toml");
        std::fs::write(&file, colors).unwrap();
        let palette = Palette::load(&file).unwrap();
        std::fs::remove_dir_all(&dir).ok();
        palette
    }

    #[test]
    fn the_palette_supplies_every_builder_colour() {
        let palette = palette(
            r##"
mode = "dark"
background = "#121212"
lighter_background = "#1e1e1e"
foreground = "#bebebe"
muted = "#333333"
accent = "#e68e0d"
green = "#ffc107"
yellow = "#b91c1c"
red = "#d35f5f"
"##,
            "full",
        );
        let settings = Settings {
            theme: "matte-black".to_string(),
            ..Settings::default()
        };

        let mut builder = ThemeBuilder::dark();
        tint(&mut builder, &settings, &palette);

        assert_eq!(builder.palette.name(), "matte-black");
        assert_eq!(builder.bg_color.unwrap().into_format::<u8, u8>().red, 0x12);
        assert_eq!(
            builder
                .primary_container_bg
                .unwrap()
                .into_format::<u8, u8>()
                .red,
            0x1e
        );
        assert_eq!(builder.accent.unwrap().into_format::<u8>().red, 0xe6);
        assert_eq!(builder.window_hint.unwrap().into_format::<u8>().red, 0xe6);
        assert_eq!(builder.neutral_tint.unwrap().into_format::<u8>().red, 0x33);
        assert_eq!(builder.text_tint.unwrap().into_format::<u8>().red, 0xbe);
        assert_eq!(builder.destructive.unwrap().into_format::<u8>().red, 0xd3);

        // The theme has to survive the derivation, which is where a bad input
        // would show up as a panic or a black-on-black component.
        let theme = builder.build();
        assert_eq!(theme.name, "matte-black");
        assert!(theme.is_dark);
    }

    /// A theme that names only the bare minimum still has to produce something
    /// COSMIC can show.
    #[test]
    fn a_sparse_palette_still_derives() {
        let palette = palette("mode = \"dark\"\nbackground = \"#101010\"\n", "sparse");
        let mut builder = ThemeBuilder::dark();
        tint(&mut builder, &Settings::default(), &palette);

        let theme = builder.build();
        assert!(theme.is_dark);
        assert_eq!(
            theme.background(false).base.into_format::<u8, u8>().red,
            0x10
        );
    }

    /// Every shipped theme has to make a theme COSMIC can render. The check
    /// that matters is not the colours but that the derivation terminates and
    /// that nothing lands token-less.
    #[test]
    fn a_light_palette_lands_in_the_light_slot() {
        let palette = palette(
            "mode = \"light\"\nbackground = \"#fbf1c7\"\nforeground = \"#3c3836\"\naccent = \"#d65d0e\"\n",
            "light",
        );
        assert!(palette.is_light());

        // Deliberately started from the *dark* builder, which is what
        // `get_entry` hands back on a machine that has no light theme on disk.
        let mut builder = ThemeBuilder::dark();
        tint(&mut builder, &Settings::default(), &palette);
        let theme = builder.build();

        assert!(!theme.is_dark, "the palette variant was corrected");
        assert_eq!(
            theme.background(false).base.into_format::<u8, u8>().red,
            0xfb
        );
    }
}
