//! `theme/settings.toml` — the non-color knobs, and the record of which theme
//! is current. Committed to the repo, so a fresh machine reproduces the look.

use std::path::Path;

use anyhow::{Context as _, Result};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct Settings {
    pub theme: String,
    pub font: Font,
    pub look: Look,
    pub wallpaper: Wallpaper,
    pub idle: Idle,
    pub lock: Lock,
    pub osd: Osd,
    pub battery: Battery,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct Font {
    /// Monospace family used by terminals and the launcher.
    pub family: String,
    /// Terminal point size.
    pub size: u32,
    /// Bar and launcher point size.
    pub ui_size: u32,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct Look {
    pub gaps: u32,
    pub border_width: u32,
    pub bar_height: u32,
    /// `top` or `bottom`.
    pub bar_position: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct Wallpaper {
    /// swaybg display mode: stretch, fill, fit, center, tile, solid_color.
    pub mode: String,
    /// Where the images live. One shared pool rather than a directory per
    /// theme: a wallpaper you like should survive a theme switch. A leading
    /// `~` expands; a relative path is taken against the dotfiles checkout.
    pub dir: String,
    /// File name within `dir`. Empty picks the first one found, which is also
    /// the fallback when the named file has since been deleted.
    pub current: String,
}

/// The idle timeline, in seconds from the last input. Steps run in the order
/// listed; a zero disables that step without disturbing the others.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct Idle {
    pub enabled: bool,
    pub dim_after: u32,
    pub screensaver_after: u32,
    pub lock_after: u32,
    pub screen_off_after: u32,
    pub suspend_after: u32,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct Lock {
    /// Show the theme's wallpaper behind the lock screen instead of a flat color.
    pub show_background: bool,
    /// Gaussian blur applied to that wallpaper, as swaylock's `<radius>x<times>`.
    pub blur: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct Osd {
    pub enabled: bool,
    pub timeout_ms: u32,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct Battery {
    /// Warn once the charge drops below this percentage.
    pub warn_below: u32,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            theme: "tokyo-night".to_string(),
            font: Font::default(),
            look: Look::default(),
            wallpaper: Wallpaper::default(),
            idle: Idle::default(),
            lock: Lock::default(),
            osd: Osd::default(),
            battery: Battery::default(),
        }
    }
}

impl Default for Idle {
    fn default() -> Self {
        Self {
            enabled: true,
            dim_after: 240,
            screensaver_after: 300,
            lock_after: 360,
            screen_off_after: 600,
            suspend_after: 1800,
        }
    }
}

impl Default for Lock {
    fn default() -> Self {
        Self {
            show_background: true,
            blur: "7x5".to_string(),
        }
    }
}

impl Default for Osd {
    fn default() -> Self {
        Self {
            enabled: true,
            timeout_ms: 1200,
        }
    }
}

impl Default for Battery {
    fn default() -> Self {
        Self { warn_below: 15 }
    }
}

impl Default for Font {
    fn default() -> Self {
        Self {
            family: "JetBrainsMono Nerd Font".to_string(),
            size: 14,
            ui_size: 12,
        }
    }
}

impl Default for Look {
    fn default() -> Self {
        Self {
            gaps: 16,
            border_width: 4,
            bar_height: 26,
            bar_position: "top".to_string(),
        }
    }
}

impl Default for Wallpaper {
    fn default() -> Self {
        Self {
            mode: "fill".to_string(),
            dir: "~/Pictures/wallpapers".to_string(),
            current: String::new(),
        }
    }
}

impl Settings {
    /// A missing file is not an error — it just means "defaults", which is what
    /// a fresh checkout should get.
    pub fn load(path: &Path) -> Result<Self> {
        match std::fs::read_to_string(path) {
            Ok(raw) => toml::from_str(&raw).with_context(|| format!("parsing {}", path.display())),
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(Self::default()),
            Err(error) => Err(error).with_context(|| format!("reading {}", path.display())),
        }
    }

    /// Look up one value by dotted path, e.g. `osd.timeout_ms` or `theme`.
    ///
    /// Scripts need to read a handful of settings, and this is cheaper than a
    /// subcommand per field — and much cheaper than teaching each script to
    /// parse TOML. Scalars come back bare so the output can be used directly;
    /// only tables and arrays keep their TOML rendering.
    pub fn get(&self, key: &str) -> Result<String> {
        let root = toml::Value::try_from(self).context("serializing settings")?;

        let mut current = &root;
        let mut walked = String::new();
        for segment in key.split('.') {
            walked.push_str(segment);
            current = current
                .get(segment)
                .with_context(|| format!("no setting '{walked}' (looking up '{key}')"))?;
            walked.push('.');
        }

        Ok(match current {
            toml::Value::String(value) => value.clone(),
            toml::Value::Integer(value) => value.to_string(),
            toml::Value::Float(value) => value.to_string(),
            toml::Value::Boolean(value) => value.to_string(),
            other => other.to_string(),
        })
    }

    pub fn save(&self, path: &Path) -> Result<()> {
        let body = toml::to_string_pretty(self).context("serializing settings")?;
        let header = "# Written by dotstyle (dotfiles/tui). Safe to hand-edit;\n\
                      # run `dotstyle render` afterwards to regenerate theme/current/.\n";
        crate::render::write_if_changed(path, &format!("{header}\n{body}"))?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trips() {
        let dir = std::env::temp_dir().join(format!("dotstyle-settings-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("settings.toml");

        let settings = Settings {
            theme: "gruvbox".to_string(),
            look: Look {
                gaps: 8,
                ..Look::default()
            },
            ..Settings::default()
        };
        settings.save(&path).unwrap();

        assert_eq!(Settings::load(&path).unwrap(), settings);
        std::fs::remove_dir_all(&dir).ok();
    }

    #[test]
    fn missing_file_is_defaults() {
        let path = Path::new("/nonexistent/dotstyle/settings.toml");
        assert_eq!(Settings::load(path).unwrap(), Settings::default());
    }

    #[test]
    fn get_reads_scalars_bare() {
        let settings = Settings::default();
        assert_eq!(settings.get("theme").unwrap(), "tokyo-night");
        assert_eq!(settings.get("osd.timeout_ms").unwrap(), "1200");
        assert_eq!(settings.get("battery.warn_below").unwrap(), "15");
        assert_eq!(settings.get("idle.enabled").unwrap(), "true");
        // Bare, not TOML-quoted: scripts use the output verbatim.
        assert!(!settings.get("font.family").unwrap().starts_with('"'));
    }

    #[test]
    fn get_names_the_missing_segment() {
        let settings = Settings::default();
        let error = settings.get("osd.nope").unwrap_err().to_string();
        assert!(error.contains("osd.nope"), "{error}");
        assert!(settings.get("nope.at.all").is_err());
    }

    #[test]
    fn partial_file_keeps_defaults_for_the_rest() {
        let settings: Settings = toml::from_str("theme = \"nord\"\n[look]\ngaps = 0\n").unwrap();
        assert_eq!(settings.theme, "nord");
        assert_eq!(settings.look.gaps, 0);
        assert_eq!(settings.look.border_width, Look::default().border_width);
        assert_eq!(settings.font.family, Font::default().family);
    }
}
