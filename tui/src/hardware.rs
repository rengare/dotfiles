//! Reading laptop hardware state for display.
//!
//! Read-only on purpose. Changing the cpufreq governor needs `pkexec` and the
//! charge limit needs `sudo`; either would put a password prompt on top of a
//! full-screen TUI, which at best corrupts the display and at worst leaves the
//! terminal in raw mode. Those changes belong to `dot-power`, where polkit's
//! agent can prompt properly. The TUI shows what is true and points at the
//! command that changes it.

use std::path::{Path, PathBuf};

/// A snapshot of the hardware state worth showing.
#[derive(Debug, Default, Clone, PartialEq)]
pub struct Hardware {
    pub governor: Option<String>,
    /// Keyboard backlight as (level, max).
    pub keyboard_backlight: Option<(u32, u32)>,
    pub battery_percent: Option<u32>,
    pub battery_status: Option<String>,
    pub charge_limit: Option<u32>,
}

impl Hardware {
    pub fn read() -> Self {
        Self {
            governor: read_trimmed(Path::new(
                "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor",
            )),
            keyboard_backlight: keyboard_backlight(),
            battery_percent: battery_dir().as_deref().and_then(battery_percent),
            battery_status: battery_dir()
                .as_deref()
                .and_then(|dir| read_trimmed(&dir.join("status"))),
            charge_limit: battery_dir().as_deref().and_then(|dir| {
                read_trimmed(&dir.join("charge_control_end_threshold"))
                    .and_then(|value| value.parse().ok())
            }),
        }
    }

    /// One line for the System tab's preview pane.
    pub fn summary(&self) -> String {
        let mut parts = Vec::new();

        if let Some(governor) = &self.governor {
            parts.push(format!("cpu {governor}"));
        }
        if let Some((level, max)) = self.keyboard_backlight {
            parts.push(format!("kbd light {level}/{max}"));
        }
        if let Some(percent) = self.battery_percent {
            let status = self.battery_status.as_deref().unwrap_or("");
            let cap = self
                .charge_limit
                .map(|limit| format!(" cap {limit}%"))
                .unwrap_or_default();
            parts.push(
                format!("battery {percent}% {status}{cap}")
                    .trim_end()
                    .to_string(),
            );
        }

        if parts.is_empty() {
            "no hardware readings available".to_string()
        } else {
            parts.join("   ")
        }
    }
}

fn read_trimmed(path: &Path) -> Option<String> {
    std::fs::read_to_string(path)
        .ok()
        .map(|body| body.trim().to_string())
        .filter(|body| !body.is_empty())
}

fn keyboard_backlight() -> Option<(u32, u32)> {
    let entries = std::fs::read_dir("/sys/class/leds").ok()?;
    let device = entries
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .find(|path| {
            path.file_name()
                .and_then(|name| name.to_str())
                .is_some_and(|name| name.contains("kbd_backlight"))
        })?;

    let level = read_trimmed(&device.join("brightness"))?.parse().ok()?;
    let max = read_trimmed(&device.join("max_brightness"))?.parse().ok()?;
    Some((level, max))
}

fn battery_dir() -> Option<PathBuf> {
    let entries = std::fs::read_dir("/sys/class/power_supply").ok()?;
    entries
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .find(|path| read_trimmed(&path.join("type")).as_deref() == Some("Battery"))
}

/// Percentage charged.
///
/// This machine's qcom-battmgr exposes no `capacity`, and its `charge_now`
/// intermittently returns "No data available", so `energy_*` is the only
/// reliable pair here — the same fallback `.config/i3blocks/battery` relies on.
fn battery_percent(dir: &Path) -> Option<u32> {
    if let Some(capacity) = read_trimmed(&dir.join("capacity")).and_then(|v| v.parse().ok()) {
        return Some(capacity);
    }

    for pair in ["energy", "charge"] {
        let now: u64 = read_trimmed(&dir.join(format!("{pair}_now")))?
            .parse()
            .ok()?;
        let full: u64 = read_trimmed(&dir.join(format!("{pair}_full")))?
            .parse()
            .ok()?;
        if let Some(percent) = (now * 100).checked_div(full) {
            return Some(percent as u32);
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn summary_survives_missing_readings() {
        assert_eq!(
            Hardware::default().summary(),
            "no hardware readings available"
        );
    }

    #[test]
    fn summary_includes_what_is_present() {
        let hardware = Hardware {
            governor: Some("ondemand".to_string()),
            keyboard_backlight: Some((1, 2)),
            battery_percent: Some(98),
            battery_status: Some("Not charging".to_string()),
            charge_limit: Some(95),
        };
        let summary = hardware.summary();
        assert!(summary.contains("cpu ondemand"), "{summary}");
        assert!(summary.contains("kbd light 1/2"), "{summary}");
        assert!(
            summary.contains("battery 98% Not charging cap 95%"),
            "{summary}"
        );
    }

    #[test]
    fn a_battery_without_a_charge_cap_omits_it() {
        let hardware = Hardware {
            battery_percent: Some(50),
            battery_status: Some("Discharging".to_string()),
            ..Hardware::default()
        };
        assert_eq!(hardware.summary(), "battery 50% Discharging");
    }

    #[test]
    fn reads_this_machine() {
        // Not asserting values — this is a smoke test that the sysfs walk finds
        // something on the machine it runs on and does not panic.
        let hardware = Hardware::read();
        assert_ne!(hardware.summary(), "");
    }
}
