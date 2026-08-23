//! Converting an alacritty palette into a dotstyle `colors.toml`.
//!
//! A port of `omarchy-theme-colors-from-alacritty`. There are ~130 alacritty
//! themes in circulation and only 22 hand-written dotstyle ones, so this is the
//! cheapest way to open the theme set up.
//!
//! The importer deliberately produces a *minimal* colors.toml — the sixteen
//! ANSI slots plus background, foreground, selection and accent. Everything
//! else (bright variants, derived shades, light/dark mode) is left to the
//! resolver in `palette.rs`, which already knows how to derive them and does so
//! identically for hand-written themes.

use std::collections::HashMap;
use std::path::Path;

use anyhow::{bail, Context, Result};

/// The eight ANSI colour names, in slot order.
const SLOT_NAMES: [&str; 8] = [
    "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white",
];

/// Convert an alacritty palette file into colors.toml text.
pub fn colors_toml_from_alacritty(source: &str) -> Result<String> {
    let colors = parse(source);

    // The eight normal colours are the irreducible minimum. A file missing any
    // of them is not a palette we can complete by guessing — better to reject
    // it than to emit a theme with a black-on-black slot nobody notices until
    // it is applied.
    let mut normal = Vec::with_capacity(8);
    for name in SLOT_NAMES {
        let key = format!("colors.normal.{name}");
        let value = colors.get(&key).with_context(|| {
            format!("not an alacritty palette: no {key} (all eight normal colors are required)")
        })?;
        normal.push(value.clone());
    }

    // Bright falls back to its normal counterpart per slot, so a palette that
    // only defines some brights still converts.
    let bright: Vec<String> = SLOT_NAMES
        .iter()
        .enumerate()
        .map(|(slot, name)| {
            colors
                .get(&format!("colors.bright.{name}"))
                .cloned()
                .unwrap_or_else(|| normal[slot].clone())
        })
        .collect();

    let background = colors
        .get("colors.primary.background")
        .cloned()
        .unwrap_or_else(|| normal[0].clone());
    let foreground = colors
        .get("colors.primary.foreground")
        .cloned()
        .unwrap_or_else(|| normal[7].clone());
    let selection = colors
        .get("colors.selection.background")
        .cloned()
        .unwrap_or_else(|| foreground.clone());

    // Slots 0 and 7 are the background and foreground by definition; a palette
    // whose normal.black differs from primary.background would otherwise give
    // terminals two different ideas of what "black" is.
    let color0 = background.clone();
    let color7 = foreground.clone();
    // Blue is the least-bad accent guess, and matches what upstream picks.
    let accent = normal[4].clone();

    let mut out = String::new();
    out.push_str("# Imported from an alacritty palette by `dotstyle theme import`.\n");
    out.push_str("# Only the base palette is recorded; bright variants, derived shades and\n");
    out.push_str("# light/dark mode are resolved from these by tui/src/palette.rs.\n\n");
    out.push_str(&format!("accent = \"{accent}\"\n"));
    out.push_str(&format!("selection = \"{selection}\"\n\n"));
    out.push_str(&format!("background = \"{background}\"\n"));
    out.push_str(&format!("foreground = \"{foreground}\"\n\n"));

    for (slot, value) in std::iter::once(&color0)
        .chain(normal[1..7].iter())
        .chain(std::iter::once(&color7))
        .enumerate()
    {
        out.push_str(&format!("color{slot} = \"{value}\"\n"));
    }
    for (slot, value) in bright.iter().enumerate() {
        out.push_str(&format!("color{} = \"{value}\"\n", slot + 8));
    }

    Ok(out)
}

/// Read a palette file and convert it.
pub fn import_file(path: &Path) -> Result<String> {
    let source =
        std::fs::read_to_string(path).with_context(|| format!("reading {}", path.display()))?;
    colors_toml_from_alacritty(&source).with_context(|| format!("importing {}", path.display()))
}

/// Derive a theme directory name from a palette file name.
pub fn theme_name_from_path(path: &Path) -> Result<String> {
    let stem = path
        .file_stem()
        .and_then(|s| s.to_str())
        .context("palette file name is not valid UTF-8")?;

    let name: String = stem
        .to_lowercase()
        .chars()
        .map(|c| if c.is_ascii_alphanumeric() { c } else { '-' })
        .collect();
    // Collapse the runs the mapping above can create, e.g. "tokyo_night-storm".
    let name = name
        .split('-')
        .filter(|part| !part.is_empty())
        .collect::<Vec<_>>()
        .join("-");

    if name.is_empty() {
        bail!("cannot derive a theme name from {}", path.display());
    }
    Ok(name)
}

/// Parse the file into `<section>.<key>` -> `#rrggbb`.
///
/// Not a TOML parse: alacritty palettes in the wild are inconsistently quoted
/// and often carry trailing comments, and a strict parser rejects files that
/// alacritty itself accepts.
fn parse(source: &str) -> HashMap<String, String> {
    // Keys written the section way (`[colors.normal] black = …`) beat keys
    // written the dotted way (`[colors] normal.black = …`) when a file has both.
    let mut section_form: HashMap<String, String> = HashMap::new();
    let mut dotted_form: HashMap<String, String> = HashMap::new();
    let mut section = String::new();

    for line in source.lines() {
        let trimmed = line.trim();

        if trimmed.starts_with('[') {
            section = match trimmed.find(']') {
                Some(end) => trimmed[1..end].to_string(),
                // An unterminated table header means anything below it has no
                // section, so keys are ignored rather than misattributed.
                None => String::new(),
            };
            continue;
        }
        if section.is_empty() {
            continue;
        }

        let Some((key, value)) = trimmed.split_once('=') else {
            continue;
        };
        let key = key.trim();
        if key.is_empty() || key.starts_with('#') {
            continue;
        }
        let Some(hex) = hex_value(value.trim()) else {
            continue;
        };

        let path = format!("{section}.{key}");
        // First occurrence of a key wins, matching upstream.
        if section == "colors" && key.contains('.') {
            dotted_form.entry(path).or_insert(hex);
        } else {
            section_form.entry(path).or_insert(hex);
        }
    }

    for (path, hex) in dotted_form {
        section_form.entry(path).or_insert(hex);
    }
    section_form
}

/// A value counts as a colour only if it is a lone six-hex-digit run, with an
/// optional `0x`/`#` prefix, optional quotes, and an optional trailing comment.
/// Anything else — a font name, a number, a bare word — is not a colour, and
/// guessing would silently produce a wrong palette.
fn hex_value(raw: &str) -> Option<String> {
    let mut value = raw;

    // Strip a trailing comment, but only outside quotes: `'#ff0000' # red` has
    // a comment, whereas `'#ff0000'` does not despite containing a '#'.
    if let Some(quote) = value.chars().next().filter(|c| *c == '\'' || *c == '"') {
        let rest = &value[1..];
        let end = rest.find(quote)?;
        value = &rest[..end];
    } else {
        // A leading '#' is the colour's own prefix, so the comment search
        // starts past it — `#1a1b26 # red` has a comment, `#1a1b26` does not.
        let search_from = usize::from(value.starts_with('#'));
        if let Some(hash) = value[search_from..].find('#') {
            value = value[..search_from + hash].trim();
        }
    }

    let value = value.trim();
    let digits = value
        .strip_prefix('#')
        .or_else(|| value.strip_prefix("0x"))
        .or_else(|| value.strip_prefix("0X"))
        .unwrap_or(value);

    if digits.len() == 6 && digits.chars().all(|c| c.is_ascii_hexdigit()) {
        Some(format!("#{}", digits.to_lowercase()))
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const MINIMAL: &str = r#"
[colors.primary]
background = '#1a1b26'
foreground = '#a9b1d6'

[colors.normal]
black   = '#15161e'
red     = '#f7768e'
green   = '#9ece6a'
yellow  = '#e0af68'
blue    = '#7aa2f7'
magenta = '#bb9af7'
cyan    = '#7dcfff'
white   = '#a9b1d6'
"#;

    #[test]
    fn converts_a_minimal_palette() {
        let out = colors_toml_from_alacritty(MINIMAL).unwrap();
        assert!(out.contains("background = \"#1a1b26\""), "{out}");
        assert!(out.contains("foreground = \"#a9b1d6\""), "{out}");
        // Slot 0 and 7 track background/foreground, not normal.black/white.
        assert!(out.contains("color0 = \"#1a1b26\""), "{out}");
        assert!(out.contains("color7 = \"#a9b1d6\""), "{out}");
        assert!(
            out.contains("accent = \"#7aa2f7\""),
            "blue is the accent: {out}"
        );
    }

    #[test]
    fn bright_falls_back_to_normal_per_slot() {
        let out = colors_toml_from_alacritty(MINIMAL).unwrap();
        // No [colors.bright] at all, so every bright mirrors its normal.
        assert!(out.contains("color9 = \"#f7768e\""), "{out}");
        assert!(out.contains("color13 = \"#bb9af7\""), "{out}");
    }

    #[test]
    fn partial_bright_is_filled_in() {
        let source = format!("{MINIMAL}\n[colors.bright]\nred = '#ff7a93'\n");
        let out = colors_toml_from_alacritty(&source).unwrap();
        assert!(out.contains("color9 = \"#ff7a93\""), "defined bright wins");
        assert!(
            out.contains("color10 = \"#9ece6a\""),
            "undefined falls back"
        );
    }

    #[test]
    fn dotted_and_section_spellings_agree() {
        let dotted = r#"
[colors]
primary.background = '#1a1b26'
primary.foreground = '#a9b1d6'
normal.black   = '#15161e'
normal.red     = '#f7768e'
normal.green   = '#9ece6a'
normal.yellow  = '#e0af68'
normal.blue    = '#7aa2f7'
normal.magenta = '#bb9af7'
normal.cyan    = '#7dcfff'
normal.white   = '#a9b1d6'
"#;
        assert_eq!(
            colors_toml_from_alacritty(dotted).unwrap(),
            colors_toml_from_alacritty(MINIMAL).unwrap()
        );
    }

    #[test]
    fn section_form_beats_dotted_form() {
        let both = format!("{MINIMAL}\n[colors]\nnormal.blue = '#000000'\n");
        let out = colors_toml_from_alacritty(&both).unwrap();
        assert!(
            out.contains("accent = \"#7aa2f7\""),
            "section form wins: {out}"
        );
    }

    #[test]
    fn a_palette_missing_normal_colors_is_rejected() {
        let incomplete = r#"
[colors.primary]
background = '#1a1b26'
foreground = '#a9b1d6'

[colors.normal]
black = '#15161e'
red   = '#f7768e'
"#;
        let error = colors_toml_from_alacritty(incomplete)
            .unwrap_err()
            .to_string();
        assert!(error.contains("colors.normal.green"), "{error}");
        assert!(error.contains("required"), "{error}");
    }

    #[test]
    fn accepts_every_hex_spelling() {
        assert_eq!(hex_value("'#1A1B26'").as_deref(), Some("#1a1b26"));
        assert_eq!(hex_value("\"#1a1b26\"").as_deref(), Some("#1a1b26"));
        assert_eq!(hex_value("#1a1b26").as_deref(), Some("#1a1b26"));
        assert_eq!(hex_value("0x1a1b26").as_deref(), Some("#1a1b26"));
        assert_eq!(hex_value("1a1b26").as_deref(), Some("#1a1b26"));
        assert_eq!(hex_value("'#1a1b26' # comment").as_deref(), Some("#1a1b26"));
        assert_eq!(hex_value("#1a1b26  # comment").as_deref(), Some("#1a1b26"));
    }

    #[test]
    fn rejects_things_that_are_not_colors() {
        assert_eq!(hex_value("'JetBrains Mono'"), None);
        assert_eq!(hex_value("14"), None);
        assert_eq!(hex_value("true"), None);
        assert_eq!(hex_value("'#12345'"), None, "five digits");
        assert_eq!(hex_value("'#1234567'"), None, "seven digits");
        assert_eq!(hex_value("'#gggggg'"), None);
    }

    #[test]
    fn non_color_keys_do_not_break_the_import() {
        // Real palettes ship alongside font and opacity settings.
        let noisy = format!(
            "{MINIMAL}\n[font]\nsize = 14\nnormal.family = 'Mono'\n\n[window]\nopacity = 0.9\n"
        );
        assert!(colors_toml_from_alacritty(&noisy).is_ok());
    }

    #[test]
    fn keys_outside_any_section_are_ignored() {
        let stray = format!("black = '#ffffff'\n{MINIMAL}");
        let out = colors_toml_from_alacritty(&stray).unwrap();
        assert!(out.contains("color1 = \"#f7768e\""), "{out}");
    }

    #[test]
    fn theme_names_are_slugified() {
        let name = |p: &str| theme_name_from_path(Path::new(p)).unwrap();
        assert_eq!(name("/x/nord.toml"), "nord");
        assert_eq!(name("/x/tokyo-night.toml"), "tokyo-night");
        assert_eq!(name("/x/gruvbox_material.toml"), "gruvbox-material");
        assert_eq!(name("/x/GitHub Light.toml"), "github-light");
        assert_eq!(name("/x/rose-pine-dawn.toml"), "rose-pine-dawn");
    }
}
