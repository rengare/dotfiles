//! Wallpaper previews.
//!
//! The terminal draws the picture. `ratatui-image` negotiates sixel / kitty /
//! iTerm2 by querying the terminal on startup, falls back to half-blocks where
//! there is no graphics protocol at all, and — importantly — keeps ratatui's
//! buffer in step with the graphics either way. That last part is what makes
//! emitting the escape sequences by hand a bad idea: the next redraw has to
//! know they are there.
//!
//! Decoding is cached per file, since a 4K JPEG takes long enough that decoding
//! it per frame would make `j`/`k` feel sticky.

use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use ratatui::layout::Rect;
use ratatui::Frame;
use ratatui_image::picker::Picker;
use ratatui_image::protocol::StatefulProtocol;
use ratatui_image::{FilterType, Resize, StatefulImage};

/// How large the preview is allowed to get, in pixels.
///
/// A pane on a HiDPI display is several thousand pixels across, and letting a
/// 4K wallpaper fill it makes the pane the subject rather than the picture —
/// besides handing the terminal a few megabytes of sixel to re-encode and
/// re-send whenever the image changes.
pub const MAX_PIXELS: (u32, u32) = (800, 600);

/// Ask the terminal how it can draw images.
///
/// This means writing a query and reading the reply, so it needs a tty in raw
/// mode and runs once, from the event loop's own setup. A terminal that does
/// not answer gets half-blocks.
/// What the preview will draw with, and why.
///
/// The reason is worth carrying around: whether a preview is a real image or an
/// approximation is the most visible thing about the Wallpaper tab, and it is
/// decided by the environment rather than by anything dotstyle chose.
pub struct Graphics {
    pub picker: Option<Picker>,
    pub note: String,
}

fn blocks(note: &str) -> Graphics {
    Graphics {
        picker: None,
        note: note.to_string(),
    }
}

/// Work out how to draw images here.
///
/// `DOTSTYLE_GRAPHICS` overrides the decision: `off` forces half-blocks, `on`
/// queries the terminal even where that is known to go wrong.
pub fn graphics() -> Graphics {
    match std::env::var("DOTSTYLE_GRAPHICS").unwrap_or_default().as_str() {
        "off" => blocks("half-blocks (DOTSTYLE_GRAPHICS=off)"),
        "on" => query(),
        // zellij answers the capability query on the terminal's behalf and then
        // re-renders the graphics through its own grid, where they tear. It is
        // singled out because `ratatui-image` has explicit handling for tmux —
        // it unwraps the passthrough — and none for zellij, so the negotiated
        // protocol is one nothing downstream honours correctly.
        _ if multiplexer() == Some("zellij") => {
            blocks("half-blocks — zellij tears sixel (DOTSTYLE_GRAPHICS=on to override)")
        }
        _ => query(),
    }
}

fn query() -> Graphics {
    match Picker::from_query_stdio() {
        Ok(picker) => Graphics {
            note: format!("{:?}", picker.protocol_type()),
            picker: Some(picker),
        },
        Err(_) => blocks("half-blocks (the terminal did not answer)"),
    }
}

/// The multiplexer between this process and the terminal, if there is one.
///
/// Worth naming when previews misbehave: the protocol is negotiated with
/// whatever answers the query, and a multiplexer answers on the terminal's
/// behalf and then re-renders the graphics itself.
pub fn multiplexer() -> Option<&'static str> {
    if std::env::var_os("ZELLIJ").is_some() {
        Some("zellij")
    } else if std::env::var_os("TMUX").is_some() {
        Some("tmux")
    } else {
        None
    }
}

/// One cell's size in pixels, or `None` when the terminal will not say.
pub fn cell_pixels() -> Option<(u16, u16)> {
    let size = crossterm::terminal::window_size().ok()?;
    if size.width == 0 || size.height == 0 || size.columns == 0 || size.rows == 0 {
        return None;
    }
    Some((size.width / size.columns, size.height / size.rows))
}

/// Shrink and centre `area` so the picture drawn into it stays within
/// [`MAX_PIXELS`].
///
/// Works in cells, because that is the only unit a `Rect` has: the pixel budget
/// is divided by the cell size to get a cell budget. Without a known cell size
/// there is nothing to convert with, so the area is left alone — an uncapped
/// preview beats a preview clamped by a guess.
pub fn clamp(area: Rect, cell: Option<(u16, u16)>) -> Rect {
    let Some((cell_w, cell_h)) = cell else {
        return area;
    };

    let max_cols = (MAX_PIXELS.0 / u32::from(cell_w).max(1)).max(1) as u16;
    let max_rows = (MAX_PIXELS.1 / u32::from(cell_h).max(1)).max(1) as u16;

    let width = area.width.min(max_cols);
    let height = area.height.min(max_rows);
    Rect {
        x: area.x + (area.width - width) / 2,
        y: area.y + (area.height - height) / 2,
        width,
        height,
    }
}

/// One wallpaper, decoded and ready to draw.
pub struct Preview {
    /// What this was decoded from, so a moved selection invalidates it.
    path: PathBuf,
    /// Dimensions of the file on disk, which is what is worth reporting — the
    /// preview has been resampled and its own size says nothing.
    pub source: (u32, u32),
    protocol: Box<StatefulProtocol>,
    /// Whether this picture has yet to be drawn once.
    fresh: bool,
}

impl Preview {
    pub fn load(path: &Path, picker: Option<&Picker>) -> Result<Self> {
        let decoded = image::ImageReader::open(path)
            .with_context(|| format!("opening {}", path.display()))?
            .with_guessed_format()
            .with_context(|| format!("reading {}", path.display()))?
            .decode()
            .with_context(|| format!("decoding {}", path.display()))?;

        let source = (decoded.width(), decoded.height());
        // No picker means the terminal was never asked — running headless, or
        // under test. Half-blocks need no negotiation, so one can be built.
        let fallback;
        let picker = match picker {
            Some(picker) => picker,
            None => {
                fallback = Picker::halfblocks();
                &fallback
            }
        };

        Ok(Self {
            path: path.to_path_buf(),
            source,
            protocol: Box::new(picker.new_resize_protocol(decoded)),
            fresh: true,
        })
    }

    pub fn is_for(&self, path: &Path) -> bool {
        self.path == path
    }

    /// Whether this is the first draw of a new picture, clearing the flag.
    ///
    /// A graphics protocol paints *over* cells rather than through them, so the
    /// terminal only drops the old image where a cell it covered is written
    /// again. Where the new picture is smaller than the one before it, those
    /// cells are never touched and the old graphic survives underneath — the
    /// caller wipes the area first when this returns true.
    ///
    /// Only on a change: wiping every frame would re-send the whole image to
    /// the terminal on each keypress, which is its own kind of flicker.
    pub fn take_fresh(&mut self) -> bool {
        std::mem::take(&mut self.fresh)
    }

    /// Draw into `area`.
    ///
    /// Returns an error only when the terminal accepted the image and then
    /// failed to encode it — worth surfacing, because the pane would otherwise
    /// just be blank with no explanation.
    pub fn draw(&mut self, frame: &mut Frame, area: Rect) -> Result<()> {
        // Nearest is the crate's default and looks it. Lanczos costs nothing
        // here: the resize happens once per size change, not once per frame.
        frame.render_stateful_widget(
            StatefulImage::default().resize(Resize::Fit(Some(FilterType::Lanczos3))),
            area,
            self.protocol.as_mut(),
        );

        match self.protocol.last_encoding_result() {
            Some(Err(error)) => Err(anyhow::anyhow!("{error}")),
            _ => Ok(()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn scratch_png(tag: &str, width: u32, height: u32) -> PathBuf {
        let path = std::env::temp_dir().join(format!(
            "dotstyle-preview-{tag}-{}-{:?}.png",
            std::process::id(),
            std::thread::current().id()
        ));
        let data: Vec<u8> = (0..width * height).flat_map(|_| [220u8, 40, 90]).collect();
        image::save_buffer(&path, &data, width, height, image::ExtendedColorType::Rgb8).unwrap();
        path
    }

    #[test]
    fn the_file_s_own_dimensions_are_reported() {
        // Not the preview's: it has been resampled, and its size says nothing.
        let path = scratch_png("size", 800, 500);
        let preview = Preview::load(&path, None).unwrap();
        assert_eq!(preview.source, (800, 500));
        std::fs::remove_file(path).ok();
    }

    #[test]
    fn a_file_that_is_not_an_image_is_an_error_not_a_panic() {
        let path =
            std::env::temp_dir().join(format!("dotstyle-preview-junk-{}", std::process::id()));
        std::fs::write(&path, b"definitely not a png").unwrap();
        assert!(Preview::load(&path, None).is_err());
        std::fs::remove_file(path).ok();
    }

    /// The decision is read from the environment, which is process-global —
    /// so these run under one lock rather than in parallel.
    fn with_env<T>(vars: &[(&str, Option<&str>)], body: impl FnOnce() -> T) -> T {
        use std::sync::Mutex;
        static LOCK: Mutex<()> = Mutex::new(());
        let _guard = LOCK.lock().unwrap_or_else(|poisoned| poisoned.into_inner());

        let saved: Vec<(String, Option<std::ffi::OsString>)> = vars
            .iter()
            .map(|(name, _)| (name.to_string(), std::env::var_os(name)))
            .collect();
        for (name, value) in vars {
            match value {
                Some(value) => unsafe { std::env::set_var(name, value) },
                None => unsafe { std::env::remove_var(name) },
            }
        }

        let result = body();

        for (name, value) in saved {
            match value {
                Some(value) => unsafe { std::env::set_var(&name, value) },
                None => unsafe { std::env::remove_var(&name) },
            }
        }
        result
    }

    #[test]
    fn zellij_gets_half_blocks_without_asking_the_terminal() {
        // It answers the capability query on the terminal's behalf and then
        // tears the graphics it re-renders, so the negotiated protocol is one
        // nothing downstream honours.
        let graphics = with_env(
            &[("ZELLIJ", Some("0")), ("DOTSTYLE_GRAPHICS", None)],
            graphics,
        );
        assert!(graphics.picker.is_none());
        assert!(
            graphics.note.contains("zellij"),
            "the reason belongs in the status line: {}",
            graphics.note
        );
    }

    #[test]
    fn the_zellij_rule_can_be_overridden() {
        // Worth having: zellij may fix this, and nothing here should be the
        // reason someone cannot find out.
        let note = with_env(
            &[("ZELLIJ", Some("0")), ("DOTSTYLE_GRAPHICS", Some("on"))],
            || graphics().note,
        );
        assert!(!note.contains("zellij"), "override ignored: {note}");
    }

    #[test]
    fn graphics_can_be_turned_off_outright() {
        let graphics = with_env(
            &[("ZELLIJ", None), ("DOTSTYLE_GRAPHICS", Some("off"))],
            graphics,
        );
        assert!(graphics.picker.is_none());
        assert!(graphics.note.contains("off"), "{}", graphics.note);
    }

    #[test]
    fn tmux_is_left_alone() {
        // ratatui-image handles tmux itself — it unwraps the passthrough — so
        // the blanket rule here is about zellij specifically, not multiplexers.
        let note = with_env(
            &[
                ("ZELLIJ", None),
                ("TMUX", Some("/tmp/tmux-1000/default,1,0")),
                ("DOTSTYLE_GRAPHICS", None),
            ],
            || graphics().note,
        );
        assert!(!note.contains("zellij"), "{note}");
    }

    #[test]
    fn a_new_picture_is_fresh_exactly_once() {
        // Once, because the wipe it triggers re-sends the whole image; every
        // frame would be its own flicker.
        let path = scratch_png("fresh", 40, 40);
        let mut preview = Preview::load(&path, None).unwrap();

        assert!(preview.take_fresh(), "the first draw wipes the pane");
        assert!(!preview.take_fresh(), "later draws must not");
        std::fs::remove_file(path).ok();
    }

    #[test]
    fn the_preview_is_capped_at_the_pixel_budget() {
        // A HiDPI pane: 200x60 cells of 15x33 px is 3000x1980, which is what
        // filling it looked like before the cap.
        let pane = Rect::new(4, 2, 200, 60);
        let capped = clamp(pane, Some((15, 33)));

        assert!(
            u32::from(capped.width) * 15 <= MAX_PIXELS.0,
            "{} cells of 15px exceeds the budget",
            capped.width
        );
        assert!(
            u32::from(capped.height) * 33 <= MAX_PIXELS.1,
            "{} cells of 33px exceeds the budget",
            capped.height
        );
        assert!(capped.width > 0 && capped.height > 0);
    }

    #[test]
    fn a_pane_inside_the_budget_is_left_alone() {
        let pane = Rect::new(0, 0, 40, 12);
        assert_eq!(clamp(pane, Some((8, 16))), pane, "40x12 cells is 320x192 px");
    }

    #[test]
    fn the_capped_preview_is_centred_in_its_pane() {
        let pane = Rect::new(10, 5, 200, 60);
        let capped = clamp(pane, Some((15, 33)));

        let left = capped.x - pane.x;
        let right = (pane.x + pane.width) - (capped.x + capped.width);
        assert!(left.abs_diff(right) <= 1, "left {left} vs right {right}");
    }

    #[test]
    fn an_unknown_cell_size_leaves_the_pane_alone() {
        // Nothing to convert pixels with; an uncapped preview beats one
        // clamped by a guess.
        let pane = Rect::new(0, 0, 200, 60);
        assert_eq!(clamp(pane, None), pane);
    }
}
