//! Making a toggle or an idle change take effect on the running session.
//!
//! Kept out of both `main.rs` and the TUI so the CLI and the TUI cannot drift
//! into doing different things for the same toggle — the bug where flipping
//! do-not-disturb from the menu pauses dunst but flipping it from the TUI only
//! writes a file.
//!
//! Every call is best-effort: over ssh, or with a tool missing, the state is
//! still recorded correctly and only the visible effect is skipped.

use std::process::{Command, Stdio};

use crate::toggles::Toggle;

fn run(program: &str, args: &[&str]) -> bool {
    Command::new(program)
        .args(args)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|status| status.success())
}

fn spawn(program: &str, args: &[&str]) {
    let _ = Command::new(program)
        .args(args)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn();
}

/// Restart the daemons described by the sway include — the idle timer and the
/// clipboard watcher. Needed whenever the timeline or stay-awake changes.
pub fn restart_session_daemons() {
    run("dot-session", &["restart"]);
}

/// Make the world match a toggle that just changed.
pub fn toggle_side_effect(toggle: Toggle, on: bool) {
    match toggle {
        Toggle::Dnd => {
            run("dunstctl", &["set-paused", if on { "true" } else { "false" }]);
        }
        // The timeline itself lives in the sway include; restarting the session
        // daemons is what makes stay-awake take effect now rather than at the
        // next reload.
        Toggle::StayAwake => restart_session_daemons(),
        Toggle::Nightlight => {
            // gammastep has no reload, so the running instance is replaced.
            run("pkill", &["-x", "gammastep"]);
            if on {
                spawn("gammastep", &["-O", "4000"]);
            }
        }
        Toggle::TouchpadOff => {
            run(
                "swaymsg",
                &[
                    "input",
                    "type:touchpad",
                    "events",
                    if on { "disabled" } else { "enabled" },
                ],
            );
        }
    }
}
