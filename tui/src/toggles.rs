//! Persistent on/off state for the desktop toggles.
//!
//! Three consumers need to agree on whether a toggle is on: the script that
//! flips it, the i3blocks indicator that displays it, and the TUI. Rather than
//! three implementations of "does this file exist", they all go through here.
//!
//! State is a marker file per toggle under `~/.local/state/dotstyle/`, the same
//! shape as `omarchy-state`. Presence means on. That makes the state readable
//! and clearable with `ls` and `rm` when something goes wrong, which matters
//! for a thing that can leave your notifications silenced.

use std::fmt;
use std::path::PathBuf;

use anyhow::{bail, Context, Result};

/// The toggles that exist. A fixed set rather than arbitrary names, so a typo
/// in a script or a bar config fails loudly instead of silently creating a
/// toggle nothing reads.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Toggle {
    /// Notification do-not-disturb.
    Dnd,
    /// Suppress the idle timeline entirely.
    StayAwake,
    /// Warm the display colour temperature.
    Nightlight,
    /// Disable the touchpad.
    TouchpadOff,
}

impl Toggle {
    pub const ALL: [Toggle; 4] = [
        Toggle::Dnd,
        Toggle::StayAwake,
        Toggle::Nightlight,
        Toggle::TouchpadOff,
    ];

    /// The name used on the command line and as the state file name.
    pub fn name(self) -> &'static str {
        match self {
            Toggle::Dnd => "dnd",
            Toggle::StayAwake => "stay-awake",
            Toggle::Nightlight => "nightlight",
            Toggle::TouchpadOff => "touchpad-off",
        }
    }

    pub fn label(self) -> &'static str {
        match self {
            Toggle::Dnd => "Do not disturb",
            Toggle::StayAwake => "Stay awake",
            Toggle::Nightlight => "Nightlight",
            Toggle::TouchpadOff => "Touchpad off",
        }
    }

    /// Shown in the bar and the menu while the toggle is on.
    pub fn icon(self) -> &'static str {
        match self {
            Toggle::Dnd => "󰂛",
            Toggle::StayAwake => "󰅶",
            Toggle::Nightlight => "󰖔",
            Toggle::TouchpadOff => "󰟸",
        }
    }

    pub fn parse(name: &str) -> Result<Self> {
        Toggle::ALL
            .into_iter()
            .find(|toggle| toggle.name() == name)
            .with_context(|| {
                format!(
                    "unknown toggle '{name}'. Known: {}",
                    Toggle::ALL
                        .iter()
                        .map(|t| t.name())
                        .collect::<Vec<_>>()
                        .join(", ")
                )
            })
    }
}

impl fmt::Display for Toggle {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(self.name())
    }
}

/// Where toggle state lives. Machine-local: it is session state, not
/// configuration, so it does not belong in the repo.
pub fn state_dir() -> PathBuf {
    std::env::var_os("DOTSTYLE_STATE_DIR")
        .map(PathBuf::from)
        .or_else(|| {
            std::env::var_os("XDG_STATE_HOME")
                .map(PathBuf::from)
                .map(|base| base.join("dotstyle"))
        })
        .or_else(|| {
            std::env::var_os("HOME")
                .map(PathBuf::from)
                .map(|home| home.join(".local/state/dotstyle"))
        })
        .unwrap_or_else(|| PathBuf::from("/tmp/dotstyle"))
}

fn marker(toggle: Toggle) -> PathBuf {
    state_dir().join(toggle.name())
}

pub fn is_on(toggle: Toggle) -> bool {
    marker(toggle).exists()
}

pub fn set(toggle: Toggle, on: bool) -> Result<()> {
    let path = marker(toggle);
    if on {
        let directory = state_dir();
        std::fs::create_dir_all(&directory)
            .with_context(|| format!("creating {}", directory.display()))?;
        std::fs::write(&path, "").with_context(|| format!("writing {}", path.display()))?;
    } else if let Err(error) = std::fs::remove_file(&path) {
        if error.kind() != std::io::ErrorKind::NotFound {
            return Err(error).with_context(|| format!("removing {}", path.display()));
        }
    }
    Ok(())
}

/// Flip the toggle, returning its new state.
pub fn flip(toggle: Toggle) -> Result<bool> {
    let next = !is_on(toggle);
    set(toggle, next)?;
    Ok(next)
}

/// Apply a `on` / `off` / `toggle` / `status` verb.
/// Whether a verb acts or only reads.
///
/// `status` reads. Everything else acts — including `on` when it is already on,
/// so that `dotstyle toggle nightlight on` re-asserts the state rather than
/// trusting a marker file that may have drifted from reality (gammastep can
/// die without anyone updating the file).
///
/// This exists because the caller fires the side effect, and firing it for a
/// read is expensive and visible: reading `nightlight` restarted gammastep,
/// which resets display gamma, and reading `stay-awake` restarted the session
/// daemons. Every `dot-run` listing did all four.
pub fn is_mutating(verb: Option<&str>) -> bool {
    !matches!(verb, Some("status"))
}

pub fn apply_verb(toggle: Toggle, verb: Option<&str>) -> Result<bool> {
    match verb {
        None | Some("toggle") => flip(toggle),
        Some("on") => {
            set(toggle, true)?;
            Ok(true)
        }
        Some("off") => {
            set(toggle, false)?;
            Ok(false)
        }
        Some("status") => Ok(is_on(toggle)),
        // Leaves the state alone but still counts as mutating, so the caller
        // fires the side effect for whatever the state already says. This is
        // how a toggle survives something that resets the world underneath it:
        // `swaymsg reload` re-applies the input config, which re-enables a
        // touchpad this had disabled.
        Some("reassert") => Ok(is_on(toggle)),
        Some(other) => {
            bail!("unknown verb '{other}'. Expected on, off, toggle, status, or reassert")
        }
    }
}

/// One line of i3blocks output: full text, short text, and nothing at all when
/// the toggle is off — an indicator that is always visible is just noise.
pub fn i3blocks_line(toggle: Toggle) -> String {
    if is_on(toggle) {
        format!("{} {}\n{}\n", toggle.icon(), toggle.label(), toggle.icon())
    } else {
        String::new()
    }
}

#[cfg(test)]
mod tests {

    #[test]
    fn status_reads_and_every_other_verb_acts() {
        // Reading a toggle used to fire its side effect, which meant listing
        // the four of them restarted gammastep and the session daemons — most
        // of a second, and a visible flash, every time the launcher opened.
        assert!(!is_mutating(Some("status")));
        assert!(is_mutating(None));
        assert!(is_mutating(Some("toggle")));
        assert!(
            is_mutating(Some("on")),
            "re-asserts a state that may have drifted"
        );
        assert!(is_mutating(Some("off")));
    }

    use super::*;

    /// Point the state dir at a scratch directory for the duration of a test.
    /// Serialised because the env var is process-wide.
    fn with_scratch<T>(body: impl FnOnce() -> T) -> T {
        static LOCK: std::sync::Mutex<()> = std::sync::Mutex::new(());
        let guard = LOCK.lock().unwrap_or_else(|poisoned| poisoned.into_inner());

        let directory = std::env::temp_dir().join(format!(
            "dotstyle-toggles-{}-{:?}",
            std::process::id(),
            std::thread::current().id()
        ));
        std::fs::create_dir_all(&directory).unwrap();
        // SAFETY: the mutex serialises every test that touches this variable.
        unsafe { std::env::set_var("DOTSTYLE_STATE_DIR", &directory) };

        let result = body();

        std::fs::remove_dir_all(&directory).ok();
        drop(guard);
        result
    }

    #[test]
    fn round_trips() {
        with_scratch(|| {
            assert!(!is_on(Toggle::Dnd), "starts off");
            set(Toggle::Dnd, true).unwrap();
            assert!(is_on(Toggle::Dnd));
            set(Toggle::Dnd, false).unwrap();
            assert!(!is_on(Toggle::Dnd));
        });
    }

    #[test]
    fn turning_off_something_already_off_is_not_an_error() {
        with_scratch(|| {
            set(Toggle::Nightlight, false).unwrap();
            set(Toggle::Nightlight, false).unwrap();
            assert!(!is_on(Toggle::Nightlight));
        });
    }

    #[test]
    fn verbs_behave() {
        with_scratch(|| {
            assert!(apply_verb(Toggle::StayAwake, Some("on")).unwrap());
            assert!(apply_verb(Toggle::StayAwake, Some("status")).unwrap());
            assert!(!apply_verb(Toggle::StayAwake, Some("toggle")).unwrap());
            assert!(
                apply_verb(Toggle::StayAwake, None).unwrap(),
                "no verb flips"
            );
            assert!(!apply_verb(Toggle::StayAwake, Some("off")).unwrap());
            assert!(apply_verb(Toggle::StayAwake, Some("nope")).is_err());
        });
    }

    #[test]
    fn reassert_reports_the_state_without_changing_it() {
        with_scratch(|| {
            assert!(!apply_verb(Toggle::TouchpadOff, Some("reassert")).unwrap());
            set(Toggle::TouchpadOff, true).unwrap();
            assert!(apply_verb(Toggle::TouchpadOff, Some("reassert")).unwrap());
            assert!(
                is_on(Toggle::TouchpadOff),
                "reassert must not flip anything"
            );
            // Unlike status, it has to reach the side effect — that is the
            // entire point of the verb.
            assert!(is_mutating(Some("reassert")));
        });
    }

    #[test]
    fn status_does_not_change_anything() {
        with_scratch(|| {
            apply_verb(Toggle::Dnd, Some("status")).unwrap();
            assert!(!is_on(Toggle::Dnd), "status must be read-only");
        });
    }

    #[test]
    fn toggles_are_independent() {
        with_scratch(|| {
            set(Toggle::Dnd, true).unwrap();
            assert!(is_on(Toggle::Dnd));
            assert!(!is_on(Toggle::Nightlight));
            assert!(!is_on(Toggle::StayAwake));
        });
    }

    #[test]
    fn unknown_names_are_rejected() {
        assert_eq!(Toggle::parse("dnd").unwrap(), Toggle::Dnd);
        assert_eq!(Toggle::parse("stay-awake").unwrap(), Toggle::StayAwake);
        let error = Toggle::parse("dndd").unwrap_err().to_string();
        assert!(error.contains("dndd"), "{error}");
        assert!(
            error.contains("stay-awake"),
            "names the alternatives: {error}"
        );
    }

    #[test]
    fn indicator_is_blank_when_off() {
        with_scratch(|| {
            assert_eq!(i3blocks_line(Toggle::Dnd), "");
            set(Toggle::Dnd, true).unwrap();
            let line = i3blocks_line(Toggle::Dnd);
            assert!(line.contains("Do not disturb"), "{line}");
            assert_eq!(line.lines().count(), 2, "full text and short text");
        });
    }
}
