//! Making a toggle or an idle change take effect on the running session.
//!
//! Kept out of both `main.rs` and the TUI so the CLI and the TUI cannot drift
//! into doing different things for the same toggle — the bug where flipping
//! do-not-disturb from the menu pauses dunst but flipping it from the TUI only
//! writes a file.
//!
//! Every call is best-effort: over ssh, or with a tool missing, the state is
//! still recorded correctly and only the visible effect is skipped.

use std::collections::BTreeSet;
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

/// A command's stdout, or `None` if it could not run or exited non-zero.
fn capture(program: &str, args: &[&str]) -> Option<String> {
    let output = Command::new(program)
        .args(args)
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output()
        .ok()?;

    output
        .status
        .success()
        .then(|| String::from_utf8_lossy(&output.stdout).into_owned())
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
            run(
                "dunstctl",
                &["set-paused", if on { "true" } else { "false" }],
            );
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
            let state = if on { "disabled" } else { "enabled" };

            let identifiers = capture("swaymsg", &["-t", "get_inputs", "-r"])
                .map(|inputs| touchpad_identifiers(&inputs))
                .unwrap_or_default();

            if identifiers.is_empty() {
                // No sway, or nothing that looks like a touchpad. The type
                // selector is still the best guess and costs nothing.
                run("swaymsg", &["input", "type:touchpad", "events", state]);
            } else {
                for identifier in identifiers {
                    run("swaymsg", &["input", &identifier, "events", state]);
                }
            }
        }
    }
}

/// Every input identifier that belongs to a physical touchpad.
///
/// `swaymsg input type:touchpad events disabled` looks like the obvious way to
/// do this and silently does not work. sway reports one libinput device per
/// evdev node, and an I2C touchpad publishes two of them: an absolute
/// `…_Touchpad` node, which is the only one typed `touchpad`, and a relative
/// `…_Mouse` node typed `pointer`. Disabling the first leaves the second
/// feeding pointer motion, so the pad keeps working and the toggle appears
/// dead.
///
/// Nodes of one device share the `vendor:product` prefix of their identifier,
/// which is what separates the touchpad's sibling from a trackpoint or a real
/// mouse — those are different hardware and must stay enabled.
fn touchpad_identifiers(inputs: &str) -> Vec<String> {
    let devices: Vec<(&str, &str)> = json_objects(inputs)
        .into_iter()
        .filter_map(|object| {
            Some((
                string_field(object, "identifier")?,
                string_field(object, "type")?,
            ))
        })
        .collect();

    let pads: BTreeSet<&str> = devices
        .iter()
        .filter(|(_, kind)| *kind == "touchpad")
        .filter_map(|(identifier, _)| hardware(identifier))
        .collect();

    // `events disabled` takes an identifier, not a node, so an identifier sway
    // also reports as a keyboard has to be left alone — disabling it would take
    // the keyboard with it. Laptop keyboards really do share an identifier with
    // a pointer node.
    let keyboards: BTreeSet<&str> = devices
        .iter()
        .filter(|(_, kind)| *kind == "keyboard")
        .map(|(identifier, _)| *identifier)
        .collect();

    let mut identifiers: Vec<String> = Vec::new();
    for (identifier, kind) in &devices {
        if !matches!(*kind, "touchpad" | "pointer") || keyboards.contains(identifier) {
            continue;
        }
        if !hardware(identifier).is_some_and(|device| pads.contains(device)) {
            continue;
        }
        if !identifiers.iter().any(|seen| seen == identifier) {
            identifiers.push((*identifier).to_owned());
        }
    }

    identifiers
}

/// The `vendor:product` prefix of a sway input identifier, which is
/// `vendor:product:name`.
fn hardware(identifier: &str) -> Option<&str> {
    let (vendor, rest) = identifier.split_once(':')?;
    let (product, _) = rest.split_once(':')?;
    Some(&identifier[..vendor.len() + 1 + product.len()])
}

/// The top-level objects of a JSON array, as slices of the source.
///
/// Enough JSON to read `swaymsg -t get_inputs`, and no dependency on a parser
/// for it. Only string contents can contain a brace, so tracking strings and
/// nesting depth is the whole job.
fn json_objects(json: &str) -> Vec<&str> {
    let mut objects = Vec::new();
    let mut depth = 0usize;
    let mut start = 0usize;
    let mut in_string = false;
    let mut escaped = false;

    for (index, byte) in json.bytes().enumerate() {
        if in_string {
            match byte {
                _ if escaped => escaped = false,
                b'\\' => escaped = true,
                b'"' => in_string = false,
                _ => {}
            }
            continue;
        }

        match byte {
            b'"' => in_string = true,
            b'{' => {
                if depth == 0 {
                    start = index;
                }
                depth += 1;
            }
            b'}' => {
                depth = depth.saturating_sub(1);
                if depth == 0 {
                    objects.push(&json[start..=index]);
                }
            }
            _ => {}
        }
    }

    objects
}

/// The value of a `"key": "value"` pair anywhere in one object. The keys this
/// reads (`identifier`, `type`) appear once and never nested, and their values
/// carry no escapes.
fn string_field<'a>(object: &'a str, key: &str) -> Option<&'a str> {
    let needle = format!("\"{key}\"");
    let mut rest = object;

    loop {
        let at = rest.find(&needle)?;
        rest = &rest[at + needle.len()..];

        let Some(value) = rest.trim_start().strip_prefix(':') else {
            continue;
        };
        let Some(value) = value.trim_start().strip_prefix('"') else {
            continue;
        };

        return value.find('"').map(|end| &value[..end]);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A ThinkPad T14s (X1E), trimmed to the fields this reads. The Elan
    /// touchpad at 1267:12693 publishes two nodes; the keyboard at 1267:13
    /// publishes a trackpoint that must survive.
    const INPUTS: &str = r#"[
      {
        "identifier": "1267:13:hid-over-i2c_04F3:000D_Mouse",
        "name": "hid-over-i2c 04F3:000D Mouse",
        "type": "pointer",
        "libinput": { "send_events": "enabled" }
      },
      {
        "identifier": "1267:13:hid-over-i2c_04F3:000D_Keyboard",
        "name": "hid-over-i2c 04F3:000D Keyboard",
        "type": "pointer",
        "libinput": { "send_events": "enabled" }
      },
      {
        "identifier": "1267:13:hid-over-i2c_04F3:000D_Keyboard",
        "name": "hid-over-i2c 04F3:000D Keyboard",
        "type": "keyboard",
        "libinput": { "send_events": "enabled" }
      },
      {
        "identifier": "1267:12693:hid-over-i2c_04F3:3195_Touchpad",
        "name": "hid-over-i2c 04F3:3195 Touchpad",
        "type": "touchpad",
        "libinput": { "send_events": "enabled" }
      },
      {
        "identifier": "1267:12693:hid-over-i2c_04F3:3195_Mouse",
        "name": "hid-over-i2c 04F3:3195 Mouse",
        "type": "pointer",
        "libinput": { "send_events": "enabled" }
      }
    ]"#;

    #[test]
    fn takes_both_nodes_of_the_touchpad() {
        // The bug: only the first of these was ever disabled, so the pad kept
        // moving the cursor with the toggle showing on.
        assert_eq!(
            touchpad_identifiers(INPUTS),
            [
                "1267:12693:hid-over-i2c_04F3:3195_Touchpad",
                "1267:12693:hid-over-i2c_04F3:3195_Mouse",
            ]
        );
    }

    #[test]
    fn leaves_other_hardware_alone() {
        let identifiers = touchpad_identifiers(INPUTS);
        assert!(
            !identifiers.iter().any(|id| id.contains("000D")),
            "the trackpoint and keyboard are different hardware: {identifiers:?}"
        );
    }

    #[test]
    fn without_a_touchpad_there_is_nothing_to_disable() {
        let mouse_only = r#"[
          { "identifier": "1133:16511:Logitech_Mouse", "type": "pointer" }
        ]"#;
        assert!(touchpad_identifiers(mouse_only).is_empty());
    }

    #[test]
    fn nonsense_input_is_not_a_panic() {
        assert!(touchpad_identifiers("").is_empty());
        assert!(touchpad_identifiers("not json {{{").is_empty());
        assert!(touchpad_identifiers(r#"[{"identifier": "no-colons"}]"#).is_empty());
    }

    #[test]
    fn reads_fields_out_of_one_object_only() {
        let objects = json_objects(INPUTS);
        assert_eq!(
            objects.len(),
            5,
            "nested libinput objects are not top level"
        );
        assert_eq!(string_field(objects[0], "type"), Some("pointer"));
        assert_eq!(string_field(objects[3], "type"), Some("touchpad"));
        assert_eq!(string_field(objects[0], "absent"), None);
    }

    #[test]
    fn a_brace_inside_a_name_does_not_split_the_object() {
        let odd = r#"[{ "identifier": "1:2:{}", "name": "a } b", "type": "touchpad" }]"#;
        assert_eq!(touchpad_identifiers(odd), ["1:2:{}"]);
    }
}
