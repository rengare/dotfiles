//! Building the `swayidle` command line from the configured timeline.
//!
//! swayidle takes its schedule as arguments, not a config file, so this is the
//! whole of the idle configuration. It lives here rather than in the shell
//! script that runs it because the ordering and disable rules are exactly the
//! kind of thing that breaks silently — a lock step that fires after the screen
//! is already off, or a `0` that gets passed through as "immediately".

use crate::settings::Settings;

/// One step of the timeline, as swayidle's `timeout <seconds> <command>`.
#[derive(Debug, Clone, PartialEq)]
pub struct Step {
    pub after: u32,
    pub command: String,
}

/// Build the timeline. Empty means idle handling is off, and the caller should
/// not start swayidle at all.
///
/// Steps come back sorted by time regardless of the order they are configured
/// in, because swayidle applies them in argument order and a lock scheduled
/// after screen-off would never be reached.
pub fn steps(settings: &Settings, lock_command: &str) -> Vec<Step> {
    if !settings.idle.enabled {
        return Vec::new();
    }

    let idle = &settings.idle;
    let mut steps: Vec<Step> = [
        // Dimming is reversible, so it gets a resume command; the others do not
        // need one because unlocking or waking already restores the display.
        (idle.dim_after, "brightnessctl -s set 10%".to_string()),
        (idle.screensaver_after, "dot-screensaver".to_string()),
        (idle.lock_after, lock_command.to_string()),
        (
            idle.screen_off_after,
            "swaymsg 'output * power off'".to_string(),
        ),
        (idle.suspend_after, "systemctl suspend".to_string()),
    ]
    .into_iter()
    // A zero means "skip this step". Passing it through would make swayidle
    // fire it the instant the session goes idle.
    .filter(|(after, _)| *after > 0)
    .map(|(after, command)| Step { after, command })
    .collect();

    steps.sort_by_key(|step| step.after);
    steps
}

/// The full swayidle argument list, ready to `exec`.
///
/// `-w` makes swayidle wait for the lock command to finish before handling the
/// sleep that follows, which is what stops the screen unlocking itself for a
/// frame on resume.
pub fn args(settings: &Settings, lock_command: &str) -> Vec<String> {
    let steps = steps(settings, lock_command);
    if steps.is_empty() {
        return Vec::new();
    }

    let mut args = vec!["-w".to_string()];

    for step in &steps {
        args.push("timeout".to_string());
        args.push(step.after.to_string());
        args.push(step.command.clone());

        // Undo the dim as soon as there is input again. Only the dim step needs
        // this; the rest are undone by unlocking or waking.
        if step.after == settings.idle.dim_after {
            args.push("resume".to_string());
            args.push("brightnessctl -r".to_string());
        }
    }

    // Lock before the machine sleeps, however it got there — lid, menu, or the
    // suspend step above. Without this, closing the lid leaves the session open.
    args.push("before-sleep".to_string());
    args.push(lock_command.to_string());

    args
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::settings::Idle;

    fn settings(idle: Idle) -> Settings {
        Settings {
            idle,
            ..Settings::default()
        }
    }

    #[test]
    fn default_timeline_is_in_ascending_order() {
        let settings = Settings::default();
        let steps = steps(&settings, "dot-lock");
        assert_eq!(steps.len(), 5);
        assert!(
            steps.windows(2).all(|pair| pair[0].after < pair[1].after),
            "swayidle applies steps in argument order: {steps:?}"
        );
    }

    #[test]
    fn misordered_config_is_sorted_not_obeyed() {
        // Someone sets lock later than screen-off; the lock must still be
        // reachable rather than shadowed.
        let steps = steps(
            &settings(Idle {
                dim_after: 100,
                screensaver_after: 0,
                lock_after: 900,
                screen_off_after: 200,
                suspend_after: 1000,
                ..Idle::default()
            }),
            "dot-lock",
        );
        let times: Vec<u32> = steps.iter().map(|step| step.after).collect();
        assert_eq!(times, vec![100, 200, 900, 1000]);
    }

    #[test]
    fn the_screensaver_runs_before_the_lock() {
        // A screensaver scheduled after the lock would never be seen.
        let steps = steps(&Settings::default(), "dot-lock");
        let position = |needle: &str| {
            steps
                .iter()
                .position(|step| step.command.contains(needle))
                .unwrap_or_else(|| panic!("no step containing {needle}: {steps:?}"))
        };
        assert!(position("dot-screensaver") < position("dot-lock"));
    }

    #[test]
    fn the_screensaver_step_can_be_switched_off_alone() {
        let steps = steps(
            &settings(Idle {
                screensaver_after: 0,
                ..Idle::default()
            }),
            "dot-lock",
        );
        assert!(!steps
            .iter()
            .any(|step| step.command.contains("screensaver")));
        assert!(steps.iter().any(|step| step.command.contains("dot-lock")));
    }

    #[test]
    fn zero_disables_only_that_step() {
        let steps = steps(
            &settings(Idle {
                dim_after: 0,
                screensaver_after: 0,
                lock_after: 300,
                screen_off_after: 0,
                suspend_after: 1800,
                ..Idle::default()
            }),
            "dot-lock",
        );
        let times: Vec<u32> = steps.iter().map(|step| step.after).collect();
        assert_eq!(times, vec![300, 1800]);
    }

    #[test]
    fn disabled_yields_no_command_at_all() {
        let settings = settings(Idle {
            enabled: false,
            ..Idle::default()
        });
        assert!(steps(&settings, "dot-lock").is_empty());
        assert!(args(&settings, "dot-lock").is_empty());
    }

    #[test]
    fn every_step_disabled_yields_no_command() {
        let settings = settings(Idle {
            enabled: true,
            dim_after: 0,
            screensaver_after: 0,
            lock_after: 0,
            screen_off_after: 0,
            suspend_after: 0,
        });
        assert!(args(&settings, "dot-lock").is_empty());
    }

    #[test]
    fn dim_gets_a_resume_and_the_others_do_not() {
        let args = args(&Settings::default(), "dot-lock");
        assert_eq!(args.iter().filter(|arg| *arg == "resume").count(), 1);
        assert!(args.contains(&"brightnessctl -r".to_string()));
    }

    #[test]
    fn always_locks_before_sleep() {
        let args = args(&Settings::default(), "dot-lock");
        let position = args.iter().position(|arg| arg == "before-sleep");
        assert!(position.is_some(), "closing the lid must lock the session");
        assert_eq!(args[position.unwrap() + 1], "dot-lock");
    }

    #[test]
    fn arguments_survive_as_discrete_strings() {
        // dot-session reads these one per line and passes them to swayidle as
        // separate argv entries, so an argument containing spaces stays a single
        // element rather than needing shell quoting anywhere.
        let args = args(&Settings::default(), "dot-lock");
        assert!(
            args.contains(&"swaymsg 'output * power off'".to_string()),
            "{args:?}"
        );
        assert!(
            args.iter().all(|arg| !arg.contains('\n')),
            "one argument per line"
        );
    }
}
