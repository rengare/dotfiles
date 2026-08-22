//! Making a render visible on the running desktop.
//!
//! Everything here is best-effort and non-fatal: dotstyle has to stay usable
//! over ssh, in a tty, or with half these programs not installed. A step that
//! cannot run is reported, never propagated as an error — a failed `dunstctl`
//! must not stop the wallpaper from changing.

pub mod external;
pub mod osc;
pub mod side_effects;

pub use side_effects::{restart_session_daemons, toggle_side_effect};
pub mod wallpaper;

use std::process::{Command, Stdio};

use crate::palette::Palette;
use crate::paths::Paths;
use crate::settings::Settings;

/// What actually happened during an apply, for the caller to report.
#[derive(Debug, Default)]
pub struct Applied {
    pub steps: Vec<String>,
    pub skipped: Vec<String>,
}

impl Applied {
    fn ok(&mut self, step: impl Into<String>) {
        self.steps.push(step.into());
    }

    fn skip(&mut self, step: impl Into<String>) {
        self.skipped.push(step.into());
    }
}

/// Whether a run puts the wallpaper on screen.
///
/// swaybg has no reload, so changing the wallpaper means killing it and
/// starting a new one — the desktop blanks for a beat each time. That is fine
/// once, on a deliberate change, and awful as a live preview while `j`/`k`
/// walk a list. So the TUI leaves the background alone until `⏎`, and only a
/// committed choice reaches swaybg.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Background {
    Apply,
    Leave,
}

/// Reload everything affected by a freshly rendered theme.
///
/// The sway reload comes first because it is the slowest and most visible;
/// the rest are cheap and run after so the desktop settles in one beat.
pub fn apply(
    paths: &Paths,
    settings: &Settings,
    palette: &Palette,
    background: Background,
) -> Applied {
    let mut applied = Applied::default();

    match external::wire_btop(paths) {
        Ok(true) => applied.ok("wired btop"),
        Ok(false) => {}
        Err(error) => applied.skip(format!("btop wiring ({error})")),
    }

    if background == Background::Apply {
        match wallpaper::apply(paths, settings) {
            Ok(Some(path)) => applied.ok(format!("wallpaper {}", path.display())),
            Ok(None) => applied.skip("wallpaper (none in the pool)".to_string()),
            Err(error) => applied.skip(format!("wallpaper ({error})")),
        }
    } else {
        applied.skip("wallpaper (not until ⏎)".to_string());
    }

    if in_sway_session() {
        if run("swaymsg", &["reload"]) {
            applied.ok("swaymsg reload");
        } else {
            applied.skip("swaymsg reload (failed)");
        }
    } else {
        applied.skip("swaymsg reload (no sway session)");
    }

    let painted = osc::broadcast(palette);
    if painted > 0 {
        applied.ok(format!("retinted {painted} terminal(s)"));
    } else {
        applied.skip("terminal retint (none running)");
    }

    // Helix and btop reload their config on these signals; dunst has a real
    // reload command. Each is a no-op when the program is not running.
    for (label, program, args) in [
        ("helix", "pkill", ["-USR1", "hx"].as_slice()),
        ("btop", "pkill", ["-USR2", "btop"].as_slice()),
        ("dunst", "dunstctl", ["reload"].as_slice()),
    ] {
        if run(program, args) {
            applied.ok(format!("reloaded {label}"));
        } else {
            applied.skip(format!("{label} (not running)"));
        }
    }

    let scheme = if palette.is_light() {
        "prefer-light"
    } else {
        "prefer-dark"
    };
    if run(
        "gsettings",
        &["set", "org.gnome.desktop.interface", "color-scheme", scheme],
    ) {
        applied.ok(format!("gtk {scheme}"));
    } else {
        applied.skip("gtk color-scheme (gsettings unavailable)");
    }

    applied
}

fn in_sway_session() -> bool {
    std::env::var_os("SWAYSOCK").is_some()
        || std::env::var("XDG_CURRENT_DESKTOP").is_ok_and(|d| d.eq_ignore_ascii_case("sway"))
}

/// Run a command, discarding its output. Returns whether it exited cleanly.
fn run(program: &str, args: &[&str]) -> bool {
    Command::new(program)
        .args(args)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|status| status.success())
}
