//! Renders every theme in the real `theme/themes/` tree.
//!
//! This is the test that matters: it is what catches a theme whose palette
//! resolves incomplete, or a template referencing a token some theme never
//! defines. Either would otherwise surface as a broken config on a live
//! desktop, and only for the one theme that happens to omit that key.

use std::path::{Path, PathBuf};

use dotstyle::palette::Palette;
use dotstyle::paths::Paths;
use dotstyle::render;
use dotstyle::settings::Settings;

fn dotfiles_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .expect("tui/ has a parent")
        .to_path_buf()
}

fn paths() -> Paths {
    Paths::from_dotfiles_root(&dotfiles_root())
}

#[test]
fn every_theme_resolves_a_complete_palette() {
    let paths = paths();
    let themes = render::list_themes(&paths).expect("listing themes");
    assert!(
        themes.len() >= 20,
        "expected the ported theme set, got {themes:?}"
    );

    for theme in themes {
        let palette = Palette::load(&paths.colors_file(&theme)).expect("loading palette");
        let missing = palette.missing_required();
        assert!(missing.is_empty(), "{theme} is missing {missing:?}");

        for (key, value) in palette.iter() {
            assert!(!value.is_empty(), "{theme}: {key} resolved to empty");
        }
    }
}

#[test]
fn every_theme_renders_every_template() {
    let paths = paths();
    // Render into a scratch directory so the test never disturbs the
    // git-tracked output the user is about to commit.
    let scratch = std::env::temp_dir().join(format!("dotstyle-render-{}", std::process::id()));
    let mut scratch_paths = paths.clone();
    scratch_paths.current = scratch.clone();

    for theme in render::list_themes(&paths).expect("listing themes") {
        let settings = Settings {
            theme: theme.clone(),
            ..Settings::default()
        };
        let rendered = render::render(&scratch_paths, &settings)
            .unwrap_or_else(|error| panic!("rendering {theme}: {error:#}"));
        assert!(!rendered.written.is_empty(), "{theme} rendered nothing");

        // A leaked directive is the specific failure this whole layer exists
        // to prevent, so assert on the output as well as on the return value.
        for name in &rendered.written {
            let body = std::fs::read_to_string(scratch.join(name)).expect("reading output");
            assert!(
                !body.contains("{{"),
                "{theme}/{name} still contains a template directive"
            );
        }
    }

    std::fs::remove_dir_all(&scratch).ok();
}

#[test]
fn light_themes_are_detected_as_light() {
    let paths = paths();
    for theme in ["catppuccin-latte", "flexoki-light", "lupine", "rose-pine"] {
        let palette = Palette::load(&paths.colors_file(theme)).expect("loading palette");
        assert!(palette.is_light(), "{theme} should resolve to light mode");
    }
    for theme in ["tokyo-night", "gruvbox", "matte-black", "solitude"] {
        let palette = Palette::load(&paths.colors_file(theme)).expect("loading palette");
        assert!(!palette.is_light(), "{theme} should resolve to dark mode");
    }
}

#[test]
fn rendering_is_deterministic() {
    let paths = paths();
    let scratch = std::env::temp_dir().join(format!("dotstyle-determinism-{}", std::process::id()));
    let mut scratch_paths = paths.clone();
    scratch_paths.current = scratch.clone();

    let settings = Settings {
        theme: "gruvbox".to_string(),
        ..Settings::default()
    };

    let first = render::render(&scratch_paths, &settings).expect("first render");
    assert!(!first.changed.is_empty(), "first render should write files");

    let second = render::render(&scratch_paths, &settings).expect("second render");
    assert!(
        second.changed.is_empty(),
        "re-rendering the same theme rewrote {:?}",
        second.changed
    );

    std::fs::remove_dir_all(&scratch).ok();
}
