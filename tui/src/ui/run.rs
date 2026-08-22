//! Terminal setup and the event loop.

use std::io;

use anyhow::Result;
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use crossterm::execute;
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use ratatui::backend::CrosstermBackend;
use ratatui::Terminal;

use crate::apply;
use crate::palette::Palette;
use crate::paths::Paths;
use crate::render;
use crate::settings::Settings;

use super::app::{Action, App, Key};
use super::draw;

/// Run the TUI, returning the settings that were committed, if any.
pub fn run(paths: Paths, settings: Settings) -> Result<Option<Settings>> {
    let mut app = App::new(paths, settings)?;
    let mut terminal = setup()?;
    // Asking the terminal what it can draw means writing a query and reading
    // the reply, so it has to happen after raw mode is on and before ratatui
    // starts drawing — nothing else may be competing for stdin.
    let graphics = super::preview::graphics();
    app.status = format!("preview: {}", graphics.note);
    app.graphics = graphics.picker;

    // Restoring the terminal must happen even if the loop panics, or a crash
    // leaves the user staring at a raw-mode shell.
    let outcome = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
        event_loop(&mut terminal, &mut app)
    }));
    restore(&mut terminal)?;

    match outcome {
        Ok(result) => result,
        Err(panic) => std::panic::resume_unwind(panic),
    }
}

type Backend = CrosstermBackend<io::Stdout>;

fn setup() -> Result<Terminal<Backend>> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    Ok(Terminal::new(CrosstermBackend::new(stdout))?)
}



fn restore(terminal: &mut Terminal<Backend>) -> Result<()> {
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;
    Ok(())
}

fn event_loop(terminal: &mut Terminal<Backend>, app: &mut App) -> Result<Option<Settings>> {
    // The palette drives the TUI's own colors too, so it is reloaded whenever
    // the previewed theme changes.
    let mut palette = load_palette(app);
    // What the last `⏎` wrote, so quitting can report it. `None` means nothing
    // was ever committed and the session was a pure preview.
    let mut committed: Option<Settings> = None;

    loop {
        terminal.draw(|frame| draw::draw(frame, app, &palette))?;

        // Waking on the debounce deadline is what makes the preview feel live
        // without applying once per keypress while a key is held down.
        if event::poll(app.poll_timeout())? {
            if let Event::Key(key) = event::read()? {
                if key.kind != KeyEventKind::Press {
                    continue;
                }
                let half_page = draw::half_page(terminal.size().map(|size| {
                    ratatui::layout::Rect::new(0, 0, size.width, size.height)
                })?);

                let action = app.on_key(translate(key), half_page);

                // A toggle flipped in the TUI has to reach the world now; the
                // app struct records the intent and the loop performs it.
                if let Some(toggle) = app.pending_side_effect.take() {
                    crate::apply::toggle_side_effect(toggle, crate::toggles::is_on(toggle));
                }

                match action {
                    Action::None => {}
                    Action::Preview => {
                        palette = load_palette(app);
                        app.schedule_preview();
                    }
                    Action::Commit => {
                        // The only place the wallpaper reaches swaybg. Every
                        // other call here previews the theme and leaves the
                        // background alone.
                        preview(app, apply::Background::Apply);
                        // The idle timeline lives in settings, so committing it
                        // has to restart the daemon that reads it.
                        crate::apply::restart_session_daemons();
                        app.settings.save(&app.paths.settings)?;
                        // Committing rebases the revert point rather than
                        // leaving: `q` from here on restores what was just
                        // saved, not what was active when the TUI opened. That
                        // makes ⏎ a save point, so several changes can be kept
                        // in one visit without reopening the TUI between them.
                        app.original = app.settings.clone();
                        committed = Some(app.settings.clone());
                        app.status = format!("saved · {}", app.settings.theme);
                    }
                    Action::Quit => {
                        if app.has_uncommitted_changes() {
                            app.settings = app.original.clone();
                            // Applying: an uncommitted wallpaper never reached
                            // swaybg, but a committed one did, and reverting to
                            // the last save has to put that back on screen.
                            preview(app, apply::Background::Apply);
                            crate::apply::restart_session_daemons();
                        }
                        return Ok(committed);
                    }
                }
            }
        }

        if app.take_due_preview() {
            preview(app, apply::Background::Leave);
        }
    }
}

fn load_palette(app: &App) -> Palette {
    Palette::load(&app.paths.colors_file(&app.settings.theme)).unwrap_or_default()
}

/// Render and apply the current settings, reporting failure in the status line
/// rather than tearing down the TUI — a theme that will not render is something
/// to see and navigate away from, not a crash.
fn preview(app: &mut App, background: apply::Background) {
    match render::render(&app.paths, &app.settings) {
        Ok(_) => {
            let palette = load_palette(app);
            let applied = apply::apply(&app.paths, &app.settings, &palette, background);
            app.status = format!("applied {} ({})", app.settings.theme, applied.steps.len());
        }
        Err(error) => app.status = format!("error: {error}"),
    }
}

fn translate(key: KeyEvent) -> Key {
    let control = key.modifiers.contains(KeyModifiers::CONTROL);
    match key.code {
        KeyCode::Char('c') if control => Key::CtrlC,
        KeyCode::Char('d') if control => Key::CtrlD,
        KeyCode::Char('u') if control => Key::CtrlU,
        KeyCode::Char(character) => Key::Char(character),
        KeyCode::Enter => Key::Enter,
        KeyCode::Esc => Key::Esc,
        KeyCode::Backspace => Key::Backspace,
        KeyCode::Tab => Key::Tab,
        KeyCode::BackTab => Key::BackTab,
        KeyCode::Up => Key::Up,
        KeyCode::Down => Key::Down,
        KeyCode::Left => Key::Left,
        KeyCode::Right => Key::Right,
        KeyCode::PageUp => Key::PageUp,
        KeyCode::PageDown => Key::PageDown,
        _ => Key::Other,
    }
}
