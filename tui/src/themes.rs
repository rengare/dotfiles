//! Creating, installing and removing themes.
//!
//! The theme set started as a fixed 22 ported from Omarchy. These are the paths
//! that make it open: import an alacritty palette, clone someone's theme repo,
//! or scaffold one from whatever is currently applied.

use std::path::Path;

use anyhow::{bail, Context, Result};

use crate::palette::Palette;
use crate::paths::Paths;
use crate::settings::Settings;

/// Write a `colors.toml` into a new theme directory.
///
/// The result is validated by loading it straight back through the resolver: a
/// theme that cannot produce a complete palette would otherwise sit in the list
/// looking fine until the moment it is applied.
pub fn create(paths: &Paths, name: &str, colors_toml: &str) -> Result<()> {
    validate_name(name)?;

    let directory = paths.theme_dir(name);
    if directory.exists() {
        bail!("theme '{name}' already exists at {}", directory.display());
    }

    std::fs::create_dir_all(&directory)
        .with_context(|| format!("creating {}", directory.display()))?;
    let colors_file = directory.join("colors.toml");
    std::fs::write(&colors_file, colors_toml)
        .with_context(|| format!("writing {}", colors_file.display()))?;

    if let Err(error) = verify(&colors_file) {
        // Leave nothing half-created behind for the theme list to pick up.
        std::fs::remove_dir_all(&directory).ok();
        return Err(error);
    }

    Ok(())
}

/// Check that a colors.toml resolves to a complete palette.
fn verify(colors_file: &Path) -> Result<()> {
    let palette = Palette::load(colors_file)?;
    let missing = palette.missing_required();
    if !missing.is_empty() {
        bail!(
            "the resulting palette is incomplete; missing: {}",
            missing.join(", ")
        );
    }
    Ok(())
}

/// Clone a theme repository into `theme/themes/`, returning the theme name.
///
/// Naming follows the convention theme repos already use: `omarchy-nord-theme`
/// and `dotstyle-nord-theme` both become `nord`.
pub fn install_from_git(paths: &Paths, url: &str) -> Result<String> {
    let name = name_from_git_url(url)?;
    validate_name(&name)?;

    let directory = paths.theme_dir(&name);
    if directory.exists() {
        bail!(
            "theme '{name}' already exists at {}; remove it first",
            directory.display()
        );
    }

    let status = std::process::Command::new("git")
        .args(["clone", "--depth", "1", url])
        .arg(&directory)
        .status()
        .context("running git clone (is git installed?)")?;
    if !status.success() {
        bail!("git clone failed for {url}");
    }

    // A cloned theme may ship an alacritty.toml instead of a colors.toml, the
    // same way Omarchy's older third-party themes do.
    let colors_file = directory.join("colors.toml");
    if !colors_file.is_file() {
        let alacritty = directory.join("alacritty.toml");
        if alacritty.is_file() {
            let colors = crate::import::import_file(&alacritty)?;
            std::fs::write(&colors_file, colors)
                .with_context(|| format!("writing {}", colors_file.display()))?;
        }
    }

    if let Err(error) = verify(&colors_file) {
        std::fs::remove_dir_all(&directory).ok();
        return Err(error.context(format!("{url} is not a usable theme")));
    }

    Ok(name)
}

/// A colors.toml holding the currently resolved palette, as a starting point.
pub fn scaffold(paths: &Paths, settings: &Settings) -> Result<String> {
    let palette = Palette::load(&paths.colors_file(&settings.theme))?;

    let mut out = String::new();
    out.push_str(&format!(
        "# Scaffolded by `dotstyle theme new` from '{}'.\n\
         # Every value here is explicit; delete any of them and the resolver in\n\
         # tui/src/palette.rs will derive them again.\n\n",
        settings.theme
    ));

    // Emit the semantic names first, then the ANSI slots, so the file reads the
    // way the hand-written themes do rather than in hash order.
    let ordered = [
        "mode",
        "accent",
        "selection",
        "background",
        "foreground",
        "muted",
        "red",
        "green",
        "yellow",
        "orange",
        "blue",
        "magenta",
        "cyan",
    ];
    for key in ordered {
        if let Some(value) = palette.get(key).filter(|v| !v.is_empty()) {
            out.push_str(&format!("{key} = \"{value}\"\n"));
        }
    }

    Ok(out)
}

/// Delete a theme directory.
pub fn remove(paths: &Paths, name: &str, active_theme: &str) -> Result<()> {
    validate_name(name)?;

    if name == active_theme {
        bail!("'{name}' is the active theme; apply another one first");
    }

    let directory = paths.theme_dir(name);
    if !directory.is_dir() {
        bail!("no theme '{name}' at {}", directory.display());
    }

    std::fs::remove_dir_all(&directory)
        .with_context(|| format!("removing {}", directory.display()))?;
    Ok(())
}

/// Theme names become directory names, so they must not be able to escape the
/// themes directory or collide with `.`/`..`.
fn validate_name(name: &str) -> Result<()> {
    if name.is_empty() {
        bail!("theme name is empty");
    }
    if !name
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_')
    {
        bail!("theme name '{name}' may only contain letters, digits, '-' and '_'");
    }
    Ok(())
}

/// `https://github.com/x/omarchy-nord-theme.git` -> `nord`.
fn name_from_git_url(url: &str) -> Result<String> {
    // scp-style SSH URLs (`git@host:org/repo.git`) have no scheme for a path
    // parser to key off, so the host prefix is stripped by hand.
    let path = match url.split_once("://") {
        Some((_, rest)) => rest,
        None => url.split_once(':').map_or(url, |(_, rest)| rest),
    };

    let base = path
        .trim_end_matches('/')
        .rsplit('/')
        .next()
        .filter(|s| !s.is_empty())
        .with_context(|| format!("cannot derive a theme name from {url}"))?;

    let name = base
        .strip_suffix(".git")
        .unwrap_or(base)
        .to_lowercase()
        .trim_start_matches("omarchy-")
        .trim_start_matches("dotstyle-")
        .trim_end_matches("-theme")
        .to_string();

    if name.is_empty() {
        bail!("cannot derive a theme name from {url}");
    }
    Ok(name)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn derives_names_from_every_url_shape() {
        let name = |url: &str| name_from_git_url(url).unwrap();
        assert_eq!(name("https://github.com/x/omarchy-nord-theme.git"), "nord");
        assert_eq!(name("https://github.com/x/nord.git"), "nord");
        assert_eq!(name("git@github.com:x/omarchy-nord-theme.git"), "nord");
        assert_eq!(
            name("https://github.com/x/dotstyle-rose-pine-theme"),
            "rose-pine"
        );
        assert_eq!(name("https://github.com/x/Some-Theme.git"), "some");
        assert_eq!(name("https://github.com/x/nord/"), "nord");
    }

    #[test]
    fn rejects_names_that_could_escape_the_themes_directory() {
        assert!(validate_name("nord").is_ok());
        assert!(validate_name("rose-pine_2").is_ok());
        assert!(validate_name("").is_err());
        assert!(validate_name("..").is_err());
        assert!(validate_name("../../etc").is_err());
        assert!(validate_name("a/b").is_err());
        assert!(validate_name("with space").is_err());
    }

    fn scratch_paths(tag: &str) -> Paths {
        let root = std::env::temp_dir().join(format!(
            "dotstyle-themes-{tag}-{}-{:?}",
            std::process::id(),
            std::thread::current().id()
        ));
        std::fs::create_dir_all(root.join("theme/themes")).unwrap();
        Paths::from_dotfiles_root(&root)
    }

    const GOOD: &str = "background = \"#1a1b26\"\nforeground = \"#a9b1d6\"\n\
                        accent = \"#7aa2f7\"\nred = \"#f7768e\"\ngreen = \"#9ece6a\"\n\
                        yellow = \"#e0af68\"\nblue = \"#7aa2f7\"\nmagenta = \"#bb9af7\"\n\
                        cyan = \"#7dcfff\"\n";

    #[test]
    fn create_then_remove() {
        let paths = scratch_paths("crud");
        create(&paths, "probe", GOOD).unwrap();
        assert!(paths.colors_file("probe").is_file());

        // Creating twice must not silently clobber a theme someone edited.
        assert!(create(&paths, "probe", GOOD).is_err());

        assert!(remove(&paths, "probe", "gruvbox").is_ok());
        assert!(!paths.theme_dir("probe").exists());
        std::fs::remove_dir_all(&paths.themes).ok();
    }

    #[test]
    fn refuses_to_remove_the_active_theme() {
        let paths = scratch_paths("active");
        create(&paths, "probe", GOOD).unwrap();
        let error = remove(&paths, "probe", "probe").unwrap_err().to_string();
        assert!(error.contains("active theme"), "{error}");
        assert!(paths.colors_file("probe").is_file(), "still there");
        std::fs::remove_dir_all(&paths.themes).ok();
    }

    #[test]
    fn an_unusable_palette_leaves_nothing_behind() {
        let paths = scratch_paths("bad");
        // No colours at all: the resolver cannot complete this.
        let error = create(&paths, "broken", "# nothing here\n").unwrap_err();
        assert!(error.to_string().contains("incomplete"), "{error}");
        assert!(
            !paths.theme_dir("broken").exists(),
            "a half-created theme would show up in the theme list"
        );
        std::fs::remove_dir_all(&paths.themes).ok();
    }
}
