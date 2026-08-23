//! dotstyle's engine, split out from the binary so integration tests can drive
//! it against the real theme tree.

pub mod apply;
pub mod color;
pub mod fonts;
pub mod hardware;
pub mod idle;
pub mod import;
pub mod keybinds;
pub mod palette;
pub mod paths;
pub mod render;
pub mod settings;
pub mod template;
pub mod themes;
pub mod toggles;
pub mod ui;
pub mod wallpaper;
