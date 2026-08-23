//! dotstyle — theme, font, wallpaper and window-manager look for these dotfiles.
//!
//! Running it with no arguments opens the TUI. The subcommands exist so the
//! same engine is scriptable and testable without a terminal.

use anyhow::{bail, Context, Result};

use dotstyle::{
    apply, idle, import, keybinds, palette, paths, render, settings, themes, toggles, ui, wallpaper,
};

use paths::Paths;
use settings::Settings;

const USAGE: &str = "\
dotstyle — theming for these dotfiles

usage:
  dotstyle                     open the TUI
  dotstyle list                list available themes
  dotstyle apply <theme>       switch to a theme and reload running apps
  dotstyle render              regenerate theme/current/ without touching the session
  dotstyle font <family> [pt]  set the monospace font
  dotstyle show                print the resolved palette of the current theme

  dotstyle toggle <name> [verb]   on | off | toggle (default) | status | reassert
  dotstyle toggle list            every toggle and whether it is on
  dotstyle toggle <name> --i3blocks   bar output; empty while the toggle is off
  dotstyle idle args              swayidle arguments, one per line, none if disabled
  dotstyle get <dotted.key>       read one setting, e.g. `dotstyle get osd.timeout_ms`

  dotstyle theme import <file> [name]   convert an alacritty palette into a theme
  dotstyle theme install <git-url>      clone a theme repo and apply it
  dotstyle theme new <name>             scaffold a theme from the current palette
  dotstyle theme remove <name>          delete a theme

  dotstyle keys                   list the sway keybindings (dot-keys pipes this to rofi)
  dotstyle graphics               report how this terminal can draw the wallpaper preview

  dotstyle wallpaper apply              put the chosen wallpaper on screen
  dotstyle wallpaper dir                print the wallpaper directory
  dotstyle wallpaper generate [theme]   derive a wallpaper from the palette
  dotstyle wallpaper generate --missing only for themes with none in the pool
  dotstyle wallpaper generate --all     re-derive for every theme
";

fn main() -> Result<()> {
    restore_sigpipe();

    let args: Vec<String> = std::env::args().skip(1).collect();
    let arguments: Vec<&str> = args.iter().map(String::as_str).collect();

    match arguments.as_slice() {
        [] => tui(),
        ["-h" | "--help" | "help"] => {
            print!("{USAGE}");
            Ok(())
        }
        ["list"] => list(),
        ["apply", theme] => apply(theme),
        ["render"] => render_only(),
        ["font", family] => font(family, None),
        ["font", family, size] => font(family, Some(size.parse()?)),
        ["show"] => show(),
        ["toggle", "list"] => toggle_list(),
        ["toggle", name] => toggle(name, None),
        ["toggle", name, "--i3blocks"] => toggle_i3blocks(name),
        ["toggle", name, verb] => toggle(name, Some(verb)),
        ["idle", "args"] => idle_args(),
        ["get", key] => get(key),
        ["theme", "import", file] => theme_import(file, None),
        ["theme", "import", file, name] => theme_import(file, Some(name)),
        ["theme", "install", url] => theme_install(url),
        ["theme", "new", name] => theme_new(name),
        ["theme", "remove", name] => theme_remove(name),
        ["keys"] => keys(),
        ["graphics"] => graphics(),
        ["wallpaper", "apply"] => wallpaper_apply(),
        ["wallpaper", "dir"] => wallpaper_dir(),
        ["wallpaper", "generate"] => wallpaper_generate(Scope::Current),
        ["wallpaper", "generate", "--missing"] => wallpaper_generate(Scope::Missing),
        ["wallpaper", "generate", "--all"] => wallpaper_generate(Scope::All),
        ["wallpaper", "generate", theme] => wallpaper_generate(Scope::One(theme.to_string())),
        ["keys", "--command-for", combination] => keys_command_for(combination),
        _ => {
            eprint!("{USAGE}");
            bail!("unrecognized arguments: {}", args.join(" "));
        }
    }
}

fn tui() -> Result<()> {
    let paths = Paths::discover()?;
    let settings = Settings::load(&paths.settings)?;
    match ui::run::run(paths, settings)? {
        Some(settings) => println!("kept {}", settings.theme),
        None => println!("nothing saved"),
    }
    Ok(())
}

/// Rust ignores SIGPIPE so that a broken pipe surfaces as an `io::Error`, but
/// every subcommand here prints with `println!`, which panics on that error.
/// The result is a panic message whenever output is piped into something that
/// exits early — `dotstyle list | head`. Restoring the default disposition
/// makes those pipelines end the way every other CLI's do.
fn restore_sigpipe() {
    // SAFETY: setting a signal disposition before any threads are spawned.
    unsafe {
        libc::signal(libc::SIGPIPE, libc::SIG_DFL);
    }
}

fn list() -> Result<()> {
    let paths = Paths::discover()?;
    let settings = Settings::load(&paths.settings)?;
    for theme in render::list_themes(&paths)? {
        let marker = if theme == settings.theme { "*" } else { " " };
        println!("{marker} {theme}");
    }
    Ok(())
}

fn render_only() -> Result<()> {
    let paths = Paths::discover()?;
    let settings = Settings::load(&paths.settings)?;
    let rendered = render::render(&paths, &settings)?;
    report(&paths, &rendered);
    Ok(())
}

fn apply(theme: &str) -> Result<()> {
    let paths = Paths::discover()?;
    let mut settings = Settings::load(&paths.settings)?;

    let available = render::list_themes(&paths)?;
    if !available.iter().any(|t| t == theme) {
        bail!(
            "unknown theme '{theme}'. Available: {}",
            available.join(", ")
        );
    }

    settings.theme = theme.to_string();
    render_save_apply(&paths, &settings)
}

fn font(family: &str, size: Option<u32>) -> Result<()> {
    let paths = Paths::discover()?;
    let mut settings = Settings::load(&paths.settings)?;
    settings.font.family = family.to_string();
    if let Some(size) = size {
        settings.font.size = size;
    }
    render_save_apply(&paths, &settings)
}

/// The full path a user-facing change takes: put the files on disk, record the
/// choice, then make the running desktop match.
fn render_save_apply(paths: &Paths, settings: &Settings) -> Result<()> {
    let rendered = render::render(paths, settings)?;
    settings.save(&paths.settings)?;
    report(paths, &rendered);

    let palette = palette::Palette::load(&paths.colors_file(&settings.theme))?;
    let applied = apply::apply(paths, settings, &palette, apply::Background::Apply);
    for step in &applied.steps {
        println!("  {step}");
    }
    for step in &applied.skipped {
        println!("  skipped: {step}");
    }
    Ok(())
}

fn show() -> Result<()> {
    let paths = Paths::discover()?;
    let settings = Settings::load(&paths.settings)?;
    let palette = palette::Palette::load(&paths.colors_file(&settings.theme))?;
    for (key, value) in palette.iter() {
        println!("{key}\t{value}");
    }
    Ok(())
}

/// Print the sway keybindings, one per line. `dot-keys` pipes this to rofi and
/// runs whatever is selected, so the command must stay the last field.
/// Report the image protocol the TUI would use for wallpaper previews.
///
/// Whether the preview is a real image or an approximation made of block glyphs
/// depends entirely on the terminal, so when it looks wrong this is the first
/// thing worth knowing. Must be run from a real terminal — the query is a write
/// to stdout and a read from stdin.
fn graphics() -> Result<()> {
    if let Some(name) = ui::preview::multiplexer() {
        println!("inside    {name}, which re-renders graphics itself");
    }

    let graphics = ui::preview::graphics();
    println!("preview   {}", graphics.note);
    match graphics.picker {
        Some(picker) => {
            let (w, h) = picker.font_size();
            println!(
                "cell      {w}x{h} px (aspect {:.2})",
                f32::from(h) / f32::from(w)
            );
            report_cap((w, h));
        }
        None => {
            if let Some(cell) = ui::preview::cell_pixels() {
                report_cap(cell);
            }
        }
    }
    Ok(())
}

/// How much of the pane the preview is allowed to use, given a cell size.
fn report_cap((cell_w, cell_h): (u16, u16)) {
    let (max_w, max_h) = ui::preview::MAX_PIXELS;
    println!(
        "preview   at most {max_w}x{max_h} px = {}x{} cells",
        max_w / u32::from(cell_w).max(1),
        max_h / u32::from(cell_h).max(1),
    );
}

/// Put the chosen wallpaper on screen without touching anything else.
///
/// `dot-session` calls this at login. Every other path into the desktop's look
/// goes through `dotstyle apply`, which does this as one of its steps — but
/// nothing re-applied the wallpaper when sway merely *started*, so a fresh
/// login came up with no swaybg at all.
fn wallpaper_apply() -> Result<()> {
    let paths = Paths::discover()?;
    let settings = Settings::load(&paths.settings)?;
    match apply::wallpaper::apply(&paths, &settings)? {
        Some(image) => println!("{}", image.display()),
        None => println!(
            "no images in {}",
            apply::wallpaper::directory(&paths, &settings).display()
        ),
    }
    Ok(())
}

/// Print the wallpaper directory, for scripts that want to open it.
fn wallpaper_dir() -> Result<()> {
    let paths = Paths::discover()?;
    let settings = Settings::load(&paths.settings)?;
    println!(
        "{}",
        apply::wallpaper::directory(&paths, &settings).display()
    );
    Ok(())
}

/// Which themes a wallpaper run covers.
enum Scope {
    Current,
    One(String),
    /// Only themes with nothing generated for them in the pool yet.
    Missing,
    All,
}

/// Derive wallpapers from palettes into the shared pool.
///
/// The output is named after the theme rather than dropped in a per-theme
/// directory, because the pool is flat and the name is the only thing that
/// says where a generated picture came from.
fn wallpaper_generate(scope: Scope) -> Result<()> {
    let paths = Paths::discover()?;
    let settings = Settings::load(&paths.settings)?;
    let pool = apply::wallpaper::directory(&paths, &settings);
    std::fs::create_dir_all(&pool).with_context(|| format!("creating {}", pool.display()))?;

    let only_missing = matches!(scope, Scope::Missing);
    let themes: Vec<String> = match scope {
        Scope::Current => vec![settings.theme.clone()],
        Scope::One(name) => vec![name],
        Scope::Missing | Scope::All => render::list_themes(&paths)?,
    };

    let mut generated = 0;
    for theme in themes {
        let output = pool.join(format!("{theme}-generated.png"));
        if only_missing && output.exists() {
            continue;
        }

        let palette = palette::Palette::load(&paths.colors_file(&theme))?;
        wallpaper::write_png(
            &palette,
            &theme,
            wallpaper::DEFAULT_WIDTH,
            wallpaper::DEFAULT_HEIGHT,
            &output,
        )?;
        generated += 1;
        println!("{}", output.display());
    }

    println!("generated {generated} wallpaper(s)");
    Ok(())
}

fn keys() -> Result<()> {
    let paths = Paths::discover()?;
    let config = paths.root.join(".config/sway/config");
    for binding in keybinds::parse_config(&config)? {
        println!("{}", binding.display());
    }
    Ok(())
}

/// Print the command bound to one key combination.
///
/// `dot-keys` needs the command back from a row the user picked, and the
/// display line is column-aligned rather than delimited — parsing it back in
/// the shell would be guesswork.
fn keys_command_for(combination: &str) -> Result<()> {
    let paths = Paths::discover()?;
    let config = paths.root.join(".config/sway/config");
    let binding = keybinds::parse_config(&config)?
        .into_iter()
        .find(|binding| binding.keys == combination)
        .with_context(|| format!("no binding for '{combination}'"))?;
    println!("{}", binding.command);
    Ok(())
}

fn theme_import(file: &str, name: Option<&str>) -> Result<()> {
    let paths = Paths::discover()?;
    let source = std::path::Path::new(file);

    let name = match name {
        Some(name) => name.to_string(),
        None => import::theme_name_from_path(source)?,
    };
    let colors = import::import_file(source)?;

    themes::create(&paths, &name, &colors)?;
    println!("imported {} -> {}", file, paths.theme_dir(&name).display());
    println!("apply it with: dotstyle apply {name}");
    Ok(())
}

fn theme_install(url: &str) -> Result<()> {
    let paths = Paths::discover()?;
    let name = themes::install_from_git(&paths, url)?;
    println!("installed {name}");
    apply(&name)
}

fn theme_new(name: &str) -> Result<()> {
    let paths = Paths::discover()?;
    let settings = Settings::load(&paths.settings)?;
    let colors = themes::scaffold(&paths, &settings)?;
    themes::create(&paths, name, &colors)?;
    println!("created {}", paths.theme_dir(name).display());
    println!("edit its colors.toml, then: dotstyle apply {name}");
    Ok(())
}

fn theme_remove(name: &str) -> Result<()> {
    let paths = Paths::discover()?;
    let settings = Settings::load(&paths.settings)?;
    themes::remove(&paths, name, &settings.theme)?;
    println!("removed {name}");
    Ok(())
}

fn get(key: &str) -> Result<()> {
    let paths = Paths::discover()?;
    println!("{}", Settings::load(&paths.settings)?.get(key)?);
    Ok(())
}

fn toggle(name: &str, verb: Option<&str>) -> Result<()> {
    let toggle = toggles::Toggle::parse(name)?;
    let on = toggles::apply_verb(toggle, verb)?;

    // A toggle nobody acts on is just a file. Each one has a side effect that
    // has to happen now, not at the next theme switch — but only when the verb
    // actually changed something. `status` is a read.
    if toggles::is_mutating(verb) {
        apply::toggle_side_effect(toggle, on);
    }

    // The report comes last, and has to. SIGPIPE is restored to its default so
    // that `dotstyle keys | rofi` ends quietly when rofi does, which means a
    // write to a stdout nobody is reading kills this process where it stands.
    // sway hands the children of `exec_always` exactly that kind of stdout, so
    // printing first killed the touchpad reassert before it reached swaymsg —
    // silently, and only when run from the config it exists to serve.
    println!("{}", if on { "on" } else { "off" });
    Ok(())
}

fn toggle_i3blocks(name: &str) -> Result<()> {
    let toggle = toggles::Toggle::parse(name)?;
    print!("{}", toggles::i3blocks_line(toggle));
    Ok(())
}

fn toggle_list() -> Result<()> {
    for toggle in toggles::Toggle::ALL {
        println!(
            "{:<14} {}",
            toggle.name(),
            if toggles::is_on(toggle) { "on" } else { "off" }
        );
    }
    Ok(())
}

/// Print the swayidle arguments one per line so `dot-session` can read them
/// into an array. Nothing is printed when the timeline is off, or when
/// stay-awake is set — which is what makes that toggle actually suppress idling
/// rather than merely recording a preference.
fn idle_args() -> Result<()> {
    if toggles::is_on(toggles::Toggle::StayAwake) {
        return Ok(());
    }

    let paths = Paths::discover()?;
    let settings = Settings::load(&paths.settings)?;
    for arg in idle::args(&settings, render::LOCK_COMMAND) {
        println!("{arg}");
    }
    Ok(())
}

fn report(paths: &Paths, rendered: &render::Rendered) {
    if rendered.changed.is_empty() {
        println!(
            "{} up to date ({} files)",
            paths.current.display(),
            rendered.written.len()
        );
    } else {
        println!(
            "wrote {} of {} files in {}:",
            rendered.changed.len(),
            rendered.written.len(),
            paths.current.display()
        );
        for name in &rendered.changed {
            println!("  {name}");
        }
    }
}
