//! Reads a theme's `colors.toml` and fills in everything it left out.
//!
//! A theme only has to define the handful of colors it cares about; templates
//! reference the full token set. This is a port of `omarchy-theme-color`'s
//! cascade, and it has to stay faithful to it — the ported themes were written
//! against these exact fallbacks, so a theme that only sets `color0..color15`
//! and one that only sets semantic names both have to come out complete.

use std::collections::BTreeMap;
use std::path::Path;

use anyhow::{Context, Result};

use crate::color::{mix, parse_hex};

/// A fully resolved token map: every name any template can reference.
#[derive(Debug, Clone, Default)]
pub struct Palette {
    values: BTreeMap<String, String>,
}

/// Canonical name -> the short legacy spelling themes may use instead.
const SHORT_ALIASES: &[(&str, &str)] = &[
    ("background", "bg"),
    ("dark_background", "dark_bg"),
    ("darker_background", "darker_bg"),
    ("lighter_background", "lighter_bg"),
    ("foreground", "fg"),
    ("dark_foreground", "dark_fg"),
    ("light_foreground", "light_fg"),
    ("bright_foreground", "bright_fg"),
];

/// Semantic name -> the ANSI slot it doubles as, in both directions.
const ANSI_ALIASES: &[(&str, &str)] = &[
    ("red", "color1"),
    ("green", "color2"),
    ("yellow", "color3"),
    ("blue", "color4"),
    ("magenta", "color5"),
    ("cyan", "color6"),
    ("bright_red", "color9"),
    ("bright_green", "color10"),
    ("bright_yellow", "color11"),
    ("bright_blue", "color12"),
    ("bright_magenta", "color13"),
    ("bright_cyan", "color14"),
];

/// Accents that get a lighter sibling derived when the theme omits one.
const BRIGHT_DERIVED: &[(&str, &str)] = &[
    ("bright_red", "red"),
    ("bright_yellow", "yellow"),
    ("bright_green", "green"),
    ("bright_cyan", "cyan"),
    ("bright_blue", "blue"),
    ("bright_magenta", "magenta"),
];

impl Palette {
    pub fn load(colors_file: &Path) -> Result<Self> {
        let raw = std::fs::read_to_string(colors_file)
            .with_context(|| format!("reading {}", colors_file.display()))?;
        let light_marker = colors_file
            .parent()
            .map(|dir| dir.join("light.mode").exists())
            .unwrap_or(false);

        let mut palette = Self {
            values: parse_colors(&raw),
        };
        palette.resolve(light_marker);
        Ok(palette)
    }

    pub fn get(&self, key: &str) -> Option<&str> {
        self.values.get(key).map(String::as_str)
    }

    pub fn iter(&self) -> impl Iterator<Item = (&String, &String)> {
        self.values.iter()
    }

    pub fn is_light(&self) -> bool {
        self.get("mode") == Some("light")
    }

    fn set(&mut self, key: &str, value: String) {
        self.values.insert(key.to_string(), value);
    }

    /// Set `key` only if it is currently missing or empty.
    fn fill(&mut self, key: &str, value: Option<String>) {
        if self.get(key).is_none_or(str::is_empty) {
            if let Some(value) = value.filter(|v| !v.is_empty()) {
                self.set(key, value);
            }
        }
    }

    fn fill_from(&mut self, key: &str, source: &str) {
        let value = self.get(source).map(str::to_string);
        self.fill(key, value);
    }

    /// First non-empty of `sources`.
    fn fill_from_any(&mut self, key: &str, sources: &[&str]) {
        let value = sources
            .iter()
            .find_map(|s| self.get(s).filter(|v| !v.is_empty()).map(str::to_string));
        self.fill(key, value);
    }

    fn fill_mixed(&mut self, key: &str, start: &str, end: &str, amount: f64) {
        let value = self.get(start).and_then(|start| mix(start, end, amount));
        self.fill(key, value);
    }

    fn resolve(&mut self, light_marker: bool) {
        // Accept the short legacy spellings before anything derives from them,
        // so `bg = "#…"` is indistinguishable from `background = "#…"` below.
        for (canonical, short) in SHORT_ALIASES {
            self.fill_from(canonical, short);
        }

        // Themes predating the semantic palette only carry ANSI slots.
        self.fill_from("background", "color0");
        self.fill_from("foreground", "color7");
        if let Some(background) = self.get("background").map(str::to_string) {
            self.set("color0", background);
        }
        if let Some(foreground) = self.get("foreground").map(str::to_string) {
            self.set("color7", foreground);
        }
        for (semantic, ansi) in ANSI_ALIASES {
            self.fill_from(semantic, ansi);
        }
        self.fill_from("magenta", "purple");
        self.fill_from("bright_magenta", "bright_purple");

        self.fill_from_any("light_foreground", &["color7", "foreground"]);
        self.fill_from_any("bright_foreground", &["color15", "foreground"]);
        // Unconditional in upstream: the cursor always tracks bright_foreground.
        if let Some(bright) = self.get("bright_foreground").map(str::to_string) {
            self.set("cursor", bright);
        }
        self.fill_from_any("lighter_background", &["color0", "background"]);
        self.fill_from_any("dark_foreground", &["color8", "foreground"]);
        self.fill_from_any("muted", &["color8", "dark_foreground"]);
        self.fill_from_any(
            "selection",
            &["selection_background", "color8", "color0", "background"],
        );
        self.fill_from("selection_background", "selection");
        self.fill_from("selection_foreground", "bright_foreground");
        self.fill_from("orange", "yellow");
        // Upstream themes always set `accent`; hand-written ones may not.
        self.fill_from_any("accent", &["blue", "foreground"]);
        self.fill_mixed("brown", "orange", "#000000", 0.5);

        self.fill_mixed("dark_background", "background", "#000000", 0.25);
        self.fill_mixed("darker_background", "background", "#000000", 0.5);
        for (bright, base) in BRIGHT_DERIVED {
            self.fill_mixed(bright, base, "#ffffff", 0.2);
        }
        self.fill_from("purple", "magenta");
        self.fill_from("bright_purple", "bright_magenta");

        // Backfill the ANSI slots from whatever the semantic names ended up as,
        // so templates written against either vocabulary resolve.
        for (semantic, ansi) in ANSI_ALIASES {
            self.fill_from(ansi, semantic);
        }
        for (ansi, semantic) in [
            ("color0", "background"),
            ("color7", "foreground"),
            ("color8", "muted"),
            ("color15", "bright_foreground"),
        ] {
            self.fill_from(ansi, semantic);
        }

        // And mirror the canonical names back onto the short spellings.
        for (canonical, short) in SHORT_ALIASES {
            if let Some(value) = self.get(canonical).map(str::to_string) {
                self.set(short, value);
            }
        }

        self.resolve_mode(light_marker);
    }

    /// Explicit `mode`, then legacy `theme_type`, then a `light.mode` marker
    /// file, then background luminance, then dark.
    fn resolve_mode(&mut self, light_marker: bool) {
        self.fill_from("mode", "theme_type");
        if self.get("mode").is_none_or(str::is_empty) {
            let mode = if light_marker {
                "light"
            } else {
                match self.get("background").and_then(parse_hex) {
                    // Upstream sums the channels rather than weighting them;
                    // 382 is half of 765.
                    Some((r, g, b)) if r as u32 + g as u32 + b as u32 > 382 => "light",
                    _ => "dark",
                }
            };
            self.set("mode", mode.to_string());
        }
        let mode = self.get("mode").unwrap_or("dark").to_string();
        self.set("theme_type", mode);
    }
}

/// `colors.toml` is a flat `key = "value"` list, not real TOML — values include
/// bare words and `rgba(...)` forms. Parse it the way upstream does.
fn parse_colors(raw: &str) -> BTreeMap<String, String> {
    let mut values = BTreeMap::new();

    for line in raw.lines() {
        let Some((key, value)) = line.split_once('=') else {
            continue;
        };
        let key: String = key
            .chars()
            .filter(|c| !matches!(c, '"' | '\'' | ' ' | '\t'))
            .collect();
        if key.is_empty() || key.starts_with('#') {
            continue;
        }
        if !key
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-')
        {
            eprintln!("dotstyle: skipping key with unsupported characters: {key}");
            continue;
        }

        // Quoted values win, which also drops any trailing inline comment.
        let value = match value.find(['"', '\'']) {
            Some(start) => {
                let quote = value.as_bytes()[start] as char;
                let rest = &value[start + 1..];
                match rest.find(quote) {
                    Some(end) => &rest[..end],
                    None => rest,
                }
            }
            None => value.split('#').next().unwrap_or("").trim(),
        };

        values.insert(key, value.trim().to_string());
    }

    values
}

/// Tokens every template is entitled to assume exist after resolution.
pub const REQUIRED_TOKENS: &[&str] = &[
    "mode",
    "accent",
    "background",
    "dark_background",
    "darker_background",
    "lighter_background",
    "foreground",
    "dark_foreground",
    "light_foreground",
    "bright_foreground",
    "cursor",
    "muted",
    "selection",
    "selection_background",
    "selection_foreground",
    "red",
    "green",
    "yellow",
    "orange",
    "blue",
    "magenta",
    "cyan",
    "brown",
    "bright_red",
    "bright_green",
    "bright_yellow",
    "bright_blue",
    "bright_magenta",
    "bright_cyan",
];

impl Palette {
    /// Names a template is entitled to reference that resolution could not
    /// produce. A non-empty result means some config would ship a raw
    /// placeholder, so callers treat it as fatal.
    pub fn missing_required(&self) -> Vec<String> {
        let semantic = REQUIRED_TOKENS.iter().map(|t| t.to_string());
        let ansi = (0..16).map(|slot| format!("color{slot}"));
        semantic
            .chain(ansi)
            .filter(|token| self.get(token).is_none_or(str::is_empty))
            .collect()
    }
}
