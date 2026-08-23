//! Retinting terminals that are already open.
//!
//! Terminals read their colors once, at startup. The only way to recolor a
//! running one is to write OSC escape sequences to its pty — which is why a
//! theme switch here changes the window you ran it from, without restarting the
//! shell. Ported from `omarchy-theme-osc` and `omarchy-theme-set-foot`.

use std::io::Write;
use std::path::PathBuf;

use crate::palette::Palette;

/// Terminals whose ptys we write to. Anything else keeps its old colors until
/// it is restarted, which is a cosmetic miss, not a failure.
const TERMINALS: &[&str] = &["foot", "alacritty", "kitty"];

/// Build the escape sequence that repaints a terminal's palette.
pub fn sequences(palette: &Palette) -> String {
    let mut out = String::new();

    // OSC 10/11/12: default foreground, background, cursor.
    // OSC 17/19: selection background and foreground.
    for (code, key) in [
        (10, "foreground"),
        (11, "background"),
        (12, "cursor"),
        (17, "selection_background"),
        (19, "selection_foreground"),
    ] {
        if let Some(value) = palette.get(key).filter(|v| !v.is_empty()) {
            out.push_str(&format!("\x1b]{code};{value}\x07"));
        }
    }

    // OSC 4: the 16 indexed ANSI slots.
    for slot in 0..16 {
        if let Some(value) = palette
            .get(&format!("color{slot}"))
            .filter(|v| !v.is_empty())
        {
            out.push_str(&format!("\x1b]4;{slot};{value}\x07"));
        }
    }

    out
}

/// Write the sequences to every pty owned by a running terminal.
///
/// Best-effort by design: a pty that vanished between enumeration and write is
/// normal, not an error worth surfacing.
pub fn broadcast(palette: &Palette) -> usize {
    let payload = sequences(palette);
    if payload.is_empty() {
        return 0;
    }

    let mut painted = 0;
    for pty in terminal_ptys() {
        if let Ok(mut handle) = std::fs::OpenOptions::new().write(true).open(&pty) {
            if handle.write_all(payload.as_bytes()).is_ok() {
                painted += 1;
            }
        }
    }
    painted
}

/// Every `/dev/pts/*` that is stdout of a child of a running terminal — i.e.
/// the shell inside each terminal window.
fn terminal_ptys() -> Vec<PathBuf> {
    let mut ptys: Vec<PathBuf> = Vec::new();

    for terminal in TERMINALS {
        for terminal_pid in pgrep(&["-x", terminal]) {
            for child_pid in pgrep(&["-P", &terminal_pid.to_string()]) {
                let stdout = PathBuf::from(format!("/proc/{child_pid}/fd/1"));
                let Ok(target) = std::fs::read_link(&stdout) else {
                    continue;
                };
                if target.starts_with("/dev/pts/") && !ptys.contains(&target) {
                    ptys.push(target);
                }
            }
        }
    }

    ptys
}

fn pgrep(args: &[&str]) -> Vec<u32> {
    let Ok(output) = std::process::Command::new("pgrep").args(args).output() else {
        return Vec::new();
    };
    String::from_utf8_lossy(&output.stdout)
        .lines()
        .filter_map(|line| line.trim().parse().ok())
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::Path;

    fn tokyo_night() -> Palette {
        let colors = Path::new(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .unwrap()
            .join("theme/themes/tokyo-night/colors.toml");
        Palette::load(&colors).unwrap()
    }

    #[test]
    fn emits_every_slot() {
        let sequences = sequences(&tokyo_night());
        assert!(sequences.contains("\x1b]11;#1a1b26\x07"), "background");
        assert!(sequences.contains("\x1b]4;1;#f7768e\x07"), "color1");
        assert!(sequences.contains("\x1b]4;15;"), "color15");
        assert_eq!(sequences.matches("\x1b]4;").count(), 16);
    }

    #[test]
    fn empty_palette_emits_nothing() {
        assert!(sequences(&Palette::default()).is_empty());
    }
}
