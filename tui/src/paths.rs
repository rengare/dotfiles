//! Locating the dotfiles tree and the theme directories inside it.

use std::path::{Path, PathBuf};

use anyhow::{bail, Result};

/// Absolute paths to everything under `dotfiles/theme/`.
#[derive(Debug, Clone)]
pub struct Paths {
    /// The dotfiles checkout itself, for things outside `theme/` — the sway
    /// config the keybinding list is parsed from, for instance.
    pub root: PathBuf,
    pub themes: PathBuf,
    pub templates: PathBuf,
    pub current: PathBuf,
    pub settings: PathBuf,
}

impl Paths {
    /// Resolve from `$DOTSTYLE_ROOT` if set (tests and one-off checkouts), else
    /// by walking up from this executable's source tree, else `~/.dotfiles`
    /// style defaults. The `theme/` directory has to already exist — creating
    /// one implicitly would silently theme the wrong tree.
    pub fn discover() -> Result<Self> {
        let candidates = discovery_candidates();
        for candidate in &candidates {
            if candidate.join("theme").join("themes").is_dir() {
                return Ok(Self::from_dotfiles_root(candidate));
            }
        }
        bail!(
            "could not find a dotfiles checkout containing theme/themes/.\n\
             Tried: {}\n\
             Set DOTSTYLE_ROOT to the dotfiles directory to override.",
            candidates
                .iter()
                .map(|p| p.display().to_string())
                .collect::<Vec<_>>()
                .join(", ")
        );
    }

    pub fn from_dotfiles_root(root: &Path) -> Self {
        let theme = root.join("theme");
        Self {
            root: root.to_path_buf(),
            themes: theme.join("themes"),
            templates: theme.join("templates"),
            current: theme.join("current"),
            settings: theme.join("settings.toml"),
        }
    }

    pub fn theme_dir(&self, name: &str) -> PathBuf {
        self.themes.join(name)
    }

    pub fn colors_file(&self, name: &str) -> PathBuf {
        self.theme_dir(name).join("colors.toml")
    }

    /// The symlink pointing at the wallpaper currently on screen.
    pub fn background_link(&self) -> PathBuf {
        self.current.join("background")
    }
}

fn discovery_candidates() -> Vec<PathBuf> {
    let mut candidates = Vec::new();

    if let Some(explicit) = std::env::var_os("DOTSTYLE_ROOT") {
        candidates.push(PathBuf::from(explicit));
    }

    // The crate lives at <dotfiles>/tui, so its parent is the checkout — this
    // is what makes `cargo run` work from anywhere without configuration.
    if let Some(parent) = Path::new(env!("CARGO_MANIFEST_DIR")).parent() {
        candidates.push(parent.to_path_buf());
    }

    // An installed binary has no manifest dir to lean on; fall back to the
    // conventional locations.
    if let Some(home) = std::env::var_os("HOME").map(PathBuf::from) {
        candidates.push(home.join("workspace/dotfiles"));
        candidates.push(home.join("dotfiles"));
        candidates.push(home.join(".dotfiles"));
    }

    candidates
}
