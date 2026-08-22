//! Turning a theme + settings into the generated files under `theme/current/`.

use std::path::Path;

use anyhow::{bail, Context as _, Result};

use crate::palette::Palette;
use crate::paths::Paths;
use crate::settings::Settings;
use crate::template::{self, Context};

/// What a render produced, so callers can decide what needs reloading.
#[derive(Debug, Default)]
pub struct Rendered {
    /// Files whose contents actually changed.
    pub changed: Vec<String>,
    /// Files written, changed or not.
    pub written: Vec<String>,
    pub light_mode: bool,
}

/// List the available themes, alphabetically. A directory only counts if it
/// has a `colors.toml`, so stray files under `themes/` are ignored.
pub fn list_themes(paths: &Paths) -> Result<Vec<String>> {
    let mut themes = Vec::new();
    let entries = std::fs::read_dir(&paths.themes)
        .with_context(|| format!("reading {}", paths.themes.display()))?;

    for entry in entries {
        let entry = entry?;
        if !entry.path().join("colors.toml").is_file() {
            continue;
        }
        if let Some(name) = entry.file_name().to_str() {
            themes.push(name.to_string());
        }
    }

    themes.sort();
    Ok(themes)
}

/// Build the variable set one render pass expands against: the resolved
/// palette plus the settings-derived tokens.
pub fn build_context(palette: &Palette, settings: &Settings) -> Context {
    let mut context = Context::new();

    for (key, value) in palette.iter() {
        context.insert(key.clone(), value.clone());
    }

    context.insert("font_family", settings.font.family.clone());
    context.insert("font_size", settings.font.size.to_string());
    context.insert("ui_font_size", settings.font.ui_size.to_string());
    context.insert("gaps", settings.look.gaps.to_string());
    context.insert("border_width", settings.look.border_width.to_string());
    context.insert("bar_height", settings.look.bar_height.to_string());
    context.insert("bar_position", settings.look.bar_position.clone());
    context.insert("theme_name", settings.theme.clone());

    context.insert("osd_timeout_ms", settings.osd.timeout_ms.to_string());
    context.insert("battery_warn_below", settings.battery.warn_below.to_string());
    context.insert("lock_blur", settings.lock.blur.clone());

    context
}

/// What the idle timeline and the lock template invoke. A single constant so
/// the sway include, the before-sleep hook and the menu cannot drift apart.
pub const LOCK_COMMAND: &str = "dot-lock";

/// Expand every `theme/templates/*.tpl` into `theme/current/`.
///
/// Nothing is applied here — this only puts files on disk, which is what makes
/// `dotstyle render` safe to run and eyeball before touching a live session.
pub fn render(paths: &Paths, settings: &Settings) -> Result<Rendered> {
    let colors_file = paths.colors_file(&settings.theme);
    if !colors_file.is_file() {
        bail!(
            "theme '{}' has no colors.toml at {}",
            settings.theme,
            colors_file.display()
        );
    }

    let palette = Palette::load(&colors_file)?;
    let missing = palette.missing_required();
    if !missing.is_empty() {
        bail!(
            "theme '{}' resolves to an incomplete palette; missing: {}",
            settings.theme,
            missing.join(", ")
        );
    }

    let context = build_context(&palette, settings);
    std::fs::create_dir_all(&paths.current)
        .with_context(|| format!("creating {}", paths.current.display()))?;

    let mut result = Rendered {
        light_mode: palette.is_light(),
        ..Rendered::default()
    };

    let mut templates: Vec<_> = std::fs::read_dir(&paths.templates)
        .with_context(|| format!("reading {}", paths.templates.display()))?
        .collect::<std::result::Result<Vec<_>, _>>()?
        .into_iter()
        .filter(|entry| entry.path().extension().is_some_and(|ext| ext == "tpl"))
        .collect();
    templates.sort_by_key(std::fs::DirEntry::file_name);

    for entry in templates {
        let source_path = entry.path();
        // `foot.ini.tpl` -> `foot.ini`
        let output_name = source_path
            .file_stem()
            .and_then(|s| s.to_str())
            .context("template file name is not valid UTF-8")?
            .to_string();

        let source = std::fs::read_to_string(&source_path)
            .with_context(|| format!("reading {}", source_path.display()))?;
        let output = template::render(&output_name, &source, &context)?;

        let output_path = paths.current.join(&output_name);
        if write_if_changed(&output_path, &output)? {
            result.changed.push(output_name.clone());
        }
        result.written.push(output_name);
    }

    // Themes ship a Neovim colorscheme spec rather than a templated palette,
    // because LazyVim wants a plugin name, not raw hex.
    copy_theme_file(paths, settings, "neovim.lua", "nvim.lua", &palette, &mut result)?;

    Ok(result)
}

/// Copy a per-theme file into `current/`, writing a stub when the theme has
/// none — a stale file from the previous theme would be worse than an empty one.
fn copy_theme_file(
    paths: &Paths,
    settings: &Settings,
    source_name: &str,
    output_name: &str,
    palette: &Palette,
    result: &mut Rendered,
) -> Result<()> {
    let source = paths.theme_dir(&settings.theme).join(source_name);
    let body = match std::fs::read_to_string(&source) {
        Ok(body) => body,
        // A theme with no colorscheme of its own keeps whatever Neovim already
        // uses, but still gets `background` right — otherwise a light theme
        // leaves the editor the only dark thing on screen.
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => format!(
            "-- {} ships no {source_name}; only the light/dark hint is applied.\n\
             vim.o.background = \"{}\"\nreturn {{}}\n",
            settings.theme,
            if palette.is_light() { "light" } else { "dark" }
        ),
        Err(error) => {
            return Err(error).with_context(|| format!("reading {}", source.display()))
        }
    };

    if write_if_changed(&paths.current.join(output_name), &body)? {
        result.changed.push(output_name.to_string());
    }
    result.written.push(output_name.to_string());
    Ok(())
}

/// Write via a temp file and rename, so a reload that races the render never
/// reads a half-written config. Returns whether the contents changed — the
/// apply layer uses that to skip reloads nobody needs, and it keeps `git
/// status` quiet when a render is a no-op.
pub fn write_if_changed(path: &Path, contents: &str) -> Result<bool> {
    if let Ok(existing) = std::fs::read_to_string(path) {
        if existing == contents {
            return Ok(false);
        }
    }

    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)
            .with_context(|| format!("creating {}", parent.display()))?;
    }

    let temp = path.with_extension(format!(
        "{}.tmp{}",
        path.extension().and_then(|e| e.to_str()).unwrap_or(""),
        std::process::id()
    ));
    std::fs::write(&temp, contents).with_context(|| format!("writing {}", temp.display()))?;
    std::fs::rename(&temp, path)
        .with_context(|| format!("renaming into {}", path.display()))?;

    Ok(true)
}
