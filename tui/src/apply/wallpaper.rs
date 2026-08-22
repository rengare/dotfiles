//! Choosing and displaying the background.

use std::path::{Path, PathBuf};

use anyhow::{Context, Result};

use crate::paths::Paths;
use crate::settings::Settings;

const IMAGE_EXTENSIONS: &[&str] = &["jpg", "jpeg", "png", "gif", "bmp", "webp"];

/// Where the images live, with `~` expanded and a relative path resolved
/// against the dotfiles checkout.
///
/// One shared pool, not a directory per theme. Wallpapers used to ship inside
/// each theme, which meant every theme switch silently threw away the picture
/// you had chosen; a pool you point at keeps the two choices independent.
pub fn directory(paths: &Paths, settings: &Settings) -> PathBuf {
    let configured = settings.wallpaper.dir.trim();
    if configured.is_empty() {
        return paths.root.join("wallpapers");
    }

    if let Some(rest) = configured.strip_prefix("~/") {
        if let Some(home) = std::env::var_os("HOME") {
            return PathBuf::from(home).join(rest);
        }
    }

    let path = PathBuf::from(configured);
    if path.is_absolute() {
        path
    } else {
        paths.root.join(path)
    }
}

/// Images in the pool, sorted so the choice is stable across runs.
pub fn list(paths: &Paths, settings: &Settings) -> Vec<PathBuf> {
    let directory = directory(paths, settings);
    let Ok(entries) = std::fs::read_dir(&directory) else {
        return Vec::new();
    };

    let mut images: Vec<PathBuf> = entries
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .filter(|path| {
            path.extension()
                .and_then(|ext| ext.to_str())
                .is_some_and(|ext| IMAGE_EXTENSIONS.contains(&ext.to_lowercase().as_str()))
        })
        .collect();

    images.sort();
    images
}

/// The image the settings point at, falling back to the first in the pool.
///
/// The fallback matters because the pool is an ordinary directory the user
/// edits outside dotstyle: a name in settings can outlive the file it refers
/// to, and a deleted wallpaper should not strand the desktop with none.
pub fn resolve(paths: &Paths, settings: &Settings) -> Option<PathBuf> {
    let images = list(paths, settings);
    if !settings.wallpaper.current.is_empty() {
        let named = images
            .iter()
            .find(|path| path.file_name().is_some_and(|n| n == settings.wallpaper.current.as_str()));
        if let Some(named) = named {
            return Some(named.clone());
        }
    }
    images.into_iter().next()
}

/// Point `theme/current/background` at the chosen image and restart swaybg.
///
/// Returns the image now on screen, or `None` when the pool is empty.
pub fn apply(paths: &Paths, settings: &Settings) -> Result<Option<PathBuf>> {
    let Some(image) = resolve(paths, settings) else {
        return Ok(None);
    };

    link(&paths.background_link(), &image)?;
    show(&image, &settings.wallpaper.mode)?;
    Ok(Some(image))
}

/// Replace the symlink atomically — swaybg may be reading through it.
fn link(link_path: &Path, target: &Path) -> Result<()> {
    if let Some(parent) = link_path.parent() {
        std::fs::create_dir_all(parent)?;
    }

    let staging = link_path.with_extension(format!("tmp{}", std::process::id()));
    let _ = std::fs::remove_file(&staging);
    std::os::unix::fs::symlink(target, &staging)
        .with_context(|| format!("linking {} -> {}", staging.display(), target.display()))?;
    std::fs::rename(&staging, link_path)
        .with_context(|| format!("moving symlink into {}", link_path.display()))?;
    Ok(())
}

/// swaybg has no reload, so the old instance is replaced. It has to outlive
/// this process — the TUI exits long before the wallpaper should disappear.
///
/// It is started through `setsid --fork` rather than spawned directly. setsid
/// forks and exits immediately, so swaybg is reparented to init and the only
/// child left here is setsid itself, which is waited for on the next line.
/// Spawning swaybg directly leaves a child that nothing ever reaps: a
/// long-running TUI collected one zombie per apply, and the previous instance
/// killed by `pkill` below became another.
fn show(image: &Path, mode: &str) -> Result<()> {
    if std::env::var_os("SWAYSOCK").is_none() {
        return Ok(());
    }

    let _ = std::process::Command::new("pkill")
        .args(["-x", "swaybg"])
        .status();

    let mut command = std::process::Command::new("setsid");
    command.args(["--fork", "swaybg", "-m", mode, "-i"]).arg(image);

    let spawned = command
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn();

    match spawned {
        // Returns as soon as setsid has forked, which is what keeps the
        // process table clean.
        Ok(mut child) => {
            let _ = child.wait();
            Ok(())
        }
        // No setsid — not Linux, or a stripped image. Fall back to a direct
        // spawn, which works but leaves the zombie described above.
        Err(_) => {
            std::process::Command::new("swaybg")
                .args(["-m", mode, "-i"])
                .arg(image)
                .stdin(std::process::Stdio::null())
                .stdout(std::process::Stdio::null())
                .stderr(std::process::Stdio::null())
                .spawn()
                .context("starting swaybg")?;
            Ok(())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A scratch dotfiles root with a scratch wallpaper pool.
    ///
    /// These tests used to read the real theme tree, which meant they were
    /// really asserting that a particular shipped theme still had artwork —
    /// so deleting the wallpapers broke tests that have nothing to do with
    /// wallpapers being shipped.
    struct Fixture {
        paths: Paths,
        root: PathBuf,
    }

    impl Fixture {
        fn new(tag: &str, images: &[&str]) -> Self {
            let root = std::env::temp_dir().join(format!(
                "dotstyle-bg-{tag}-{}-{:?}",
                std::process::id(),
                std::thread::current().id()
            ));
            let pool = root.join("wallpapers");
            std::fs::create_dir_all(&pool).unwrap();
            for image in images {
                std::fs::write(pool.join(image), b"not really an image").unwrap();
            }
            Self {
                paths: Paths::from_dotfiles_root(&root),
                root,
            }
        }

        /// Settings pointing at the scratch pool by relative path, so the test
        /// never depends on `$HOME`.
        fn settings(&self, current: &str) -> Settings {
            Settings {
                wallpaper: crate::settings::Wallpaper {
                    dir: "wallpapers".to_string(),
                    current: current.to_string(),
                    ..Default::default()
                },
                ..Settings::default()
            }
        }
    }

    impl Drop for Fixture {
        fn drop(&mut self) {
            std::fs::remove_dir_all(&self.root).ok();
        }
    }

    #[test]
    fn lists_images_sorted_and_ignores_other_files() {
        let fixture = Fixture::new("list", &["b.png", "a.jpg", "notes.txt"]);
        let images = list(&fixture.paths, &fixture.settings(""));

        let names: Vec<String> = images
            .iter()
            .map(|p| p.file_name().unwrap().to_string_lossy().into_owned())
            .collect();
        assert_eq!(names, vec!["a.jpg", "b.png"], "sorted, and no notes.txt");
    }

    #[test]
    fn falls_back_when_the_named_file_is_gone() {
        // The pool is an ordinary directory the user edits outside dotstyle,
        // so the name in settings can outlive the file it refers to.
        let fixture = Fixture::new("fallback", &["first.png", "second.png"]);
        let settings = fixture.settings("deleted-last-week.png");

        let resolved = resolve(&fixture.paths, &settings).expect("falls back");
        assert_eq!(resolved.file_name().unwrap(), "first.png");
    }

    #[test]
    fn honours_an_explicit_choice() {
        let fixture = Fixture::new("explicit", &["first.png", "second.png"]);
        let settings = fixture.settings("second.png");

        let resolved = resolve(&fixture.paths, &settings).expect("named file exists");
        assert_eq!(resolved.file_name().unwrap(), "second.png");
    }

    #[test]
    fn an_empty_pool_resolves_to_nothing() {
        // Applying a theme must still succeed and leave the desktop alone.
        let fixture = Fixture::new("empty", &[]);
        let settings = fixture.settings("");

        assert!(list(&fixture.paths, &settings).is_empty());
        assert!(resolve(&fixture.paths, &settings).is_none());
        assert!(
            apply(&fixture.paths, &settings).unwrap().is_none(),
            "not an error"
        );
    }

    #[test]
    fn the_directory_setting_expands_a_leading_tilde() {
        let fixture = Fixture::new("tilde", &[]);
        let mut settings = fixture.settings("");
        settings.wallpaper.dir = "~/Pictures/wallpapers".to_string();

        let home = PathBuf::from(std::env::var_os("HOME").expect("HOME is set in tests"));
        assert_eq!(
            directory(&fixture.paths, &settings),
            home.join("Pictures/wallpapers")
        );
    }

    #[test]
    fn an_absolute_directory_setting_is_used_as_is() {
        let fixture = Fixture::new("absolute", &[]);
        let mut settings = fixture.settings("");
        settings.wallpaper.dir = "/srv/art".to_string();

        assert_eq!(
            directory(&fixture.paths, &settings),
            PathBuf::from("/srv/art")
        );
    }
}
