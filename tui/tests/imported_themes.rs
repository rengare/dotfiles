//! Imports every alacritty palette in `tests/fixtures/alacritty/` and puts the
//! result through the same resolver and templates a hand-written theme uses.
//!
//! These fixtures are real palettes recovered from this repo's own history
//! (`git show HEAD:.config/alacritty/themes/<name>.toml`), so they exercise the
//! quoting, ordering and light/dark variety found in the wild — a better test
//! of the resolver than the 22 curated themes, which were all written to the
//! same house style.

use std::path::{Path, PathBuf};

use dotstyle::palette::Palette;
use dotstyle::paths::Paths;
use dotstyle::render;
use dotstyle::settings::Settings;
use dotstyle::{import, themes};

fn fixtures() -> Vec<PathBuf> {
    let directory = Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/alacritty");
    let mut files: Vec<PathBuf> = std::fs::read_dir(&directory)
        .expect("fixture directory")
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .filter(|path| path.extension().is_some_and(|ext| ext == "toml"))
        .collect();
    files.sort();
    assert!(
        files.len() >= 8,
        "expected the recovered corpus, got {files:?}"
    );
    files
}

fn dotfiles_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .expect("tui/ has a parent")
        .to_path_buf()
}

/// A Paths whose themes and output directories are scratch, but whose templates
/// are the real ones — the templates are what the import has to satisfy.
fn scratch_paths(tag: &str) -> Paths {
    let root = dotfiles_root();
    let scratch =
        std::env::temp_dir().join(format!("dotstyle-import-{tag}-{}", std::process::id()));
    std::fs::create_dir_all(scratch.join("themes")).unwrap();

    let mut paths = Paths::from_dotfiles_root(&root);
    paths.themes = scratch.join("themes");
    paths.current = scratch.join("current");
    paths
}

#[test]
fn every_recovered_palette_imports_and_resolves() {
    let paths = scratch_paths("resolve");

    for fixture in fixtures() {
        let name = import::theme_name_from_path(&fixture).expect("theme name");
        let colors = import::import_file(&fixture)
            .unwrap_or_else(|error| panic!("importing {}: {error:#}", fixture.display()));

        // `create` verifies completeness itself and refuses to leave a broken
        // theme on disk, so a failure here is the assertion.
        themes::create(&paths, &name, &colors).unwrap_or_else(|error| panic!("{name}: {error:#}"));

        let palette = Palette::load(&paths.colors_file(&name)).expect("loading");
        assert!(
            palette.missing_required().is_empty(),
            "{name} resolved incomplete"
        );
        // A palette whose background equals its foreground would render an
        // unreadable desktop, and is the most likely shape of a parsing slip.
        assert_ne!(
            palette.get("background"),
            palette.get("foreground"),
            "{name} has identical background and foreground"
        );
    }

    std::fs::remove_dir_all(paths.themes.parent().unwrap()).ok();
}

#[test]
fn every_imported_palette_renders_every_template() {
    let paths = scratch_paths("render");

    for fixture in fixtures() {
        let name = import::theme_name_from_path(&fixture).expect("theme name");
        let colors = import::import_file(&fixture).expect("import");
        themes::create(&paths, &name, &colors).expect("create");

        let settings = Settings {
            theme: name.clone(),
            ..Settings::default()
        };
        let rendered = render::render(&paths, &settings)
            .unwrap_or_else(|error| panic!("rendering {name}: {error:#}"));

        for output in &rendered.written {
            let body = std::fs::read_to_string(paths.current.join(output)).expect("output");
            assert!(
                !body.contains("{{"),
                "{name}/{output} kept a template directive"
            );
        }
    }

    std::fs::remove_dir_all(paths.themes.parent().unwrap()).ok();
}

#[test]
fn light_palettes_are_detected_as_light() {
    let paths = scratch_paths("mode");

    // Detection is by background luminance, so these are the cases where a
    // slip would be visible: a light theme with a dark GTK scheme and a dark
    // Neovim background.
    for (fixture, expect_light) in [
        ("solarized_light.toml", true),
        ("github_light.toml", true),
        ("papercolor_light.toml", true),
        ("nord.toml", false),
        ("dracula.toml", false),
        ("catppuccin_mocha.toml", false),
    ] {
        let path = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("tests/fixtures/alacritty")
            .join(fixture);
        let name = import::theme_name_from_path(&path).expect("name");
        let colors = import::import_file(&path).expect("import");
        themes::create(&paths, &name, &colors).expect("create");

        let palette = Palette::load(&paths.colors_file(&name)).expect("load");
        assert_eq!(
            palette.is_light(),
            expect_light,
            "{fixture} light-mode detection"
        );
    }

    std::fs::remove_dir_all(paths.themes.parent().unwrap()).ok();
}
