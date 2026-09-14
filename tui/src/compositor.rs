//! Which compositor this process is running under.
//!
//! One detection, shared by `apply` (which reload command to run) and `main`
//! (which keybinding parser and config file back `dotstyle keys`) — so the
//! two never disagree about what session dotstyle is in.

/// Hyprland sets this to its instance socket name; nothing else does.
pub fn is_hyprland() -> bool {
    std::env::var_os("HYPRLAND_INSTANCE_SIGNATURE").is_some()
}

pub fn is_sway() -> bool {
    !is_hyprland()
        && (std::env::var_os("SWAYSOCK").is_some()
            || std::env::var("XDG_CURRENT_DESKTOP").is_ok_and(|d| d.eq_ignore_ascii_case("sway")))
}
