//! Wiring for config directories that live outside the dotfiles checkout.
//!
//! Most apps are themed by a one-time `include` line in a tracked config. btop
//! is the exception: its config directory holds runtime state it rewrites on
//! exit, so tracking it in git would mean a dirty working tree after every run.
//! Instead the link is (re)created here, which also makes a fresh machine work
//! without a separate install step.

use std::path::Path;

use anyhow::{Context, Result};

use crate::paths::Paths;

const BTOP_THEME_NAME: &str = "dotstyle";

/// Ensure btop loads the generated theme. Idempotent, and a no-op when btop
/// has never been run (no config directory to wire up).
pub fn wire_btop(paths: &Paths) -> Result<bool> {
    let Some(home) = std::env::var_os("HOME").map(std::path::PathBuf::from) else {
        return Ok(false);
    };
    let btop = home.join(".config/btop");
    if !btop.is_dir() {
        return Ok(false);
    }

    let themes = btop.join("themes");
    std::fs::create_dir_all(&themes).with_context(|| format!("creating {}", themes.display()))?;
    symlink(
        &paths.current.join("btop.theme"),
        &themes.join(format!("{BTOP_THEME_NAME}.theme")),
    )?;

    select_btop_theme(&btop.join("btop.conf"))
}

/// Point `color_theme` at our generated theme, preserving the rest of the file.
fn select_btop_theme(config: &Path) -> Result<bool> {
    let Ok(body) = std::fs::read_to_string(config) else {
        return Ok(false);
    };

    let wanted = format!("color_theme = \"{BTOP_THEME_NAME}\"");
    if body.lines().any(|line| line.trim() == wanted) {
        return Ok(false);
    }

    let mut replaced = false;
    let mut updated: Vec<String> = body
        .lines()
        .map(|line| {
            if line.trim_start().starts_with("color_theme") {
                replaced = true;
                wanted.clone()
            } else {
                line.to_string()
            }
        })
        .collect();
    if !replaced {
        updated.push(wanted);
    }

    crate::render::write_if_changed(config, &format!("{}\n", updated.join("\n")))
}

/// Replace whatever is at `link_path` with a symlink to `target`.
fn symlink(target: &Path, link_path: &Path) -> Result<()> {
    if std::fs::read_link(link_path).is_ok_and(|existing| existing == target) {
        return Ok(());
    }
    let _ = std::fs::remove_file(link_path);
    std::os::unix::fs::symlink(target, link_path)
        .with_context(|| format!("linking {} -> {}", link_path.display(), target.display()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rewrites_color_theme_in_place() {
        let dir = std::env::temp_dir().join(format!("dotstyle-btop-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let config = dir.join("btop.conf");
        std::fs::write(&config, "#comment\ncolor_theme = \"Default\"\nupdate_ms = 2000\n").unwrap();

        assert!(select_btop_theme(&config).unwrap(), "first call changes it");
        let body = std::fs::read_to_string(&config).unwrap();
        assert!(body.contains("color_theme = \"dotstyle\""));
        assert!(body.contains("update_ms = 2000"), "other keys survive");
        assert!(!body.contains("Default"));

        assert!(!select_btop_theme(&config).unwrap(), "second call is a no-op");
        std::fs::remove_dir_all(&dir).ok();
    }

    #[test]
    fn appends_when_the_key_is_absent() {
        let dir = std::env::temp_dir().join(format!("dotstyle-btop-add-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let config = dir.join("btop.conf");
        std::fs::write(&config, "update_ms = 2000\n").unwrap();

        assert!(select_btop_theme(&config).unwrap());
        assert!(std::fs::read_to_string(&config)
            .unwrap()
            .contains("color_theme = \"dotstyle\""));
        std::fs::remove_dir_all(&dir).ok();
    }
}
