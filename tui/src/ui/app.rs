//! TUI state and the vim keymap.
//!
//! Kept free of terminal and drawing concerns so the whole interaction model —
//! including `gg`, filtering, and the preview/revert contract — is testable
//! without a pty.

use std::cell::RefCell;
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};

use crate::fonts;
use crate::paths::Paths;
use crate::toggles::{self, Toggle};
use crate::render;
use crate::settings::Settings;
use crate::ui::preview::Preview;

/// How long the selection must sit still before the desktop is retinted.
/// Long enough that holding `j` scrolls freely, short enough to feel live.
pub const PREVIEW_DEBOUNCE: Duration = Duration::from_millis(120);

/// How long to wait for a key when nothing else is pending. Long rather than
/// infinite so a resize or a stray signal still gets a frame eventually.
const IDLE_POLL: Duration = Duration::from_secs(30);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Tab {
    Themes,
    Font,
    Wallpaper,
    Look,
    System,
}

impl Tab {
    pub const ALL: [Tab; 5] = [
        Tab::Themes,
        Tab::Font,
        Tab::Wallpaper,
        Tab::Look,
        Tab::System,
    ];

    pub fn title(self) -> &'static str {
        match self {
            Tab::Themes => "Themes",
            Tab::Font => "Font",
            Tab::Wallpaper => "Wallpaper",
            Tab::Look => "Look",
            Tab::System => "System",
        }
    }

    fn index(self) -> usize {
        Tab::ALL.iter().position(|t| *t == self).unwrap_or(0)
    }
}

/// Normal mode navigates; Filter mode sends every printable key to the query.
/// This is a mode rather than "is the query non-empty" so that `j` typed into
/// a filter never moves the cursor.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Mode {
    Normal,
    Filter,
}

/// Rows on the System tab: every toggle, then the idle timeline.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SystemRow {
    Toggle(Toggle),
    IdleEnabled,
    DimAfter,
    ScreensaverAfter,
    LockAfter,
    ScreenOffAfter,
    SuspendAfter,
}

impl SystemRow {
    pub fn all() -> Vec<SystemRow> {
        Toggle::ALL
            .into_iter()
            .map(SystemRow::Toggle)
            .chain([
                SystemRow::IdleEnabled,
                SystemRow::DimAfter,
                SystemRow::ScreensaverAfter,
                SystemRow::LockAfter,
                SystemRow::ScreenOffAfter,
                SystemRow::SuspendAfter,
            ])
            .collect()
    }

    pub fn label(self) -> String {
        match self {
            SystemRow::Toggle(toggle) => toggle.label().to_string(),
            SystemRow::IdleEnabled => "Idle handling".to_string(),
            SystemRow::DimAfter => "Dim after".to_string(),
            SystemRow::ScreensaverAfter => "Screensaver after".to_string(),
            SystemRow::LockAfter => "Lock after".to_string(),
            SystemRow::ScreenOffAfter => "Screen off after".to_string(),
            SystemRow::SuspendAfter => "Suspend after".to_string(),
        }
    }
}

/// Seconds rendered the way a person reads them.
pub fn format_seconds(seconds: u32) -> String {
    match seconds {
        0 => "off".to_string(),
        s if s % 60 == 0 && s >= 60 => format!("{} min", s / 60),
        s => format!("{s} s"),
    }
}

/// The editable fields on the Look tab, in display order.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LookField {
    Gaps,
    BorderWidth,
    BarHeight,
    BarPosition,
    FontSize,
    UiFontSize,
}

impl LookField {
    pub const ALL: [LookField; 6] = [
        LookField::Gaps,
        LookField::BorderWidth,
        LookField::BarHeight,
        LookField::BarPosition,
        LookField::FontSize,
        LookField::UiFontSize,
    ];

    pub fn label(self) -> &'static str {
        match self {
            LookField::Gaps => "Gaps",
            LookField::BorderWidth => "Border width",
            LookField::BarHeight => "Bar height",
            LookField::BarPosition => "Bar position",
            LookField::FontSize => "Terminal font size",
            LookField::UiFontSize => "UI font size",
        }
    }
}

/// One scrollable list plus its filter.
#[derive(Debug, Default)]
pub struct Picker {
    items: Vec<String>,
    /// Indices into `items` that survive the filter.
    visible: Vec<usize>,
    cursor: usize,
    query: String,
}

impl Picker {
    pub fn new(items: Vec<String>) -> Self {
        let mut picker = Self {
            visible: (0..items.len()).collect(),
            items,
            cursor: 0,
            query: String::new(),
        };
        picker.refilter();
        picker
    }

    pub fn items(&self) -> &[String] {
        &self.items
    }

    /// The filtered rows, as (index into `items`, text).
    pub fn visible(&self) -> impl Iterator<Item = (usize, &String)> {
        self.visible.iter().map(|&index| (index, &self.items[index]))
    }

    pub fn len(&self) -> usize {
        self.visible.len()
    }

    pub fn is_empty(&self) -> bool {
        self.visible.is_empty()
    }

    /// Position within the *filtered* list, which is what the UI highlights.
    pub fn cursor(&self) -> usize {
        self.cursor
    }

    pub fn selected(&self) -> Option<&str> {
        self.visible
            .get(self.cursor)
            .map(|&index| self.items[index].as_str())
    }

    pub fn query(&self) -> &str {
        &self.query
    }

    /// Move by `delta` rows, clamping at both ends rather than wrapping —
    /// wrapping makes a held `j` disorienting on a short list.
    pub fn step(&mut self, delta: isize) -> bool {
        if self.visible.is_empty() {
            return false;
        }
        let last = self.visible.len() - 1;
        let target = (self.cursor as isize + delta).clamp(0, last as isize) as usize;
        let moved = target != self.cursor;
        self.cursor = target;
        moved
    }

    pub fn jump(&mut self, index: usize) -> bool {
        let target = index.min(self.visible.len().saturating_sub(1));
        let moved = target != self.cursor;
        self.cursor = target;
        moved
    }

    pub fn last(&mut self) -> bool {
        self.jump(self.visible.len().saturating_sub(1))
    }

    /// Put the cursor on `item` if it is present, so opening a tab starts on
    /// whatever is currently active rather than at the top.
    pub fn select_value(&mut self, item: &str) {
        if let Some(position) = self.visible.iter().position(|&i| self.items[i] == item) {
            self.cursor = position;
        }
    }

    pub fn set_query(&mut self, query: String) {
        self.query = query;
        self.refilter();
    }

    pub fn push_query(&mut self, character: char) {
        self.query.push(character);
        self.refilter();
    }

    pub fn pop_query(&mut self) {
        self.query.pop();
        self.refilter();
    }

    /// Subsequence match, ranked so the obvious answer comes first.
    ///
    /// Plain subsequence matching alone is too loose to lead with: "kan"
    /// legitimately matches "hackerman", which would sort above "kanagawa" and
    /// make typing a theme's actual name select the wrong one.
    fn refilter(&mut self) {
        let query = self.query.to_lowercase();

        let mut scored: Vec<(u8, usize)> = self
            .items
            .iter()
            .enumerate()
            .filter_map(|(index, item)| {
                match_score(&item.to_lowercase(), &query).map(|score| (score, index))
            })
            .collect();
        // Sorting by (score, original index) keeps equally-good matches in
        // alphabetical order.
        scored.sort();
        self.visible = scored.into_iter().map(|(_, index)| index).collect();
        self.cursor = 0;
    }
}

/// `None` when there is no match; otherwise a rank, lower being better:
/// 0 for a prefix, 1 for a substring, 2 for a scattered subsequence.
fn match_score(haystack: &str, needle: &str) -> Option<u8> {
    if needle.is_empty() || haystack.starts_with(needle) {
        return Some(0);
    }
    if haystack.contains(needle) {
        return Some(1);
    }

    let mut characters = haystack.chars();
    let is_subsequence = needle
        .chars()
        .all(|wanted| characters.any(|actual| actual == wanted));
    is_subsequence.then_some(2)
}

/// What the event loop should do after handling a key.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Action {
    None,
    /// The selection changed; schedule a debounced preview.
    Preview,
    /// Persist the current settings and keep them.
    Commit,
    /// Leave, restoring whatever was active on entry.
    Quit,
}

pub struct App {
    pub paths: Paths,
    /// Live settings, including uncommitted preview changes.
    pub settings: Settings,
    /// What to restore if the user quits without committing.
    pub original: Settings,
    pub tab: Tab,
    pub mode: Mode,
    pub themes: Picker,
    pub fonts: Picker,
    pub wallpapers: Picker,
    pub look_cursor: usize,
    pub system_cursor: usize,
    /// Half of `g g`: set by the first `g`, cleared by anything else.
    pending_g: bool,
    /// Selection when filter mode was entered, restored if it is escaped.
    filter_anchor: Option<String>,
    /// When the pending preview becomes due, if one is pending.
    preview_due: Option<Instant>,
    pub status: String,
    pub show_help: bool,
    /// A toggle flipped in the TUI whose side effect the event loop still has
    /// to run — the app struct stays free of process spawning.
    pub pending_side_effect: Option<Toggle>,
    /// How this terminal draws images, if it can. Filled in by the event loop
    /// once the terminal is in raw mode, since finding out means asking it.
    pub graphics: Option<ratatui_image::picker::Picker>,
    /// The decoded preview for the highlighted wallpaper.
    ///
    /// Behind a `RefCell` because drawing is the only place that knows how big
    /// the pane is, and it takes `&App`. Threading `&mut App` through the whole
    /// render path for what is derived, throwaway state would be a worse trade.
    /// A failure is cached too, so a file that is not really an image is not
    /// re-decoded on every frame.
    preview: RefCell<Option<CachedPreview>>,
}

struct CachedPreview {
    path: PathBuf,
    result: Result<Preview, String>,
}

impl App {
    pub fn new(paths: Paths, settings: Settings) -> anyhow::Result<Self> {
        let mut themes = Picker::new(render::list_themes(&paths)?);
        themes.select_value(&settings.theme);

        let mut families = fonts::monospace_families();
        if families.is_empty() {
            families.push(settings.font.family.clone());
        }
        let mut fonts = Picker::new(families);
        fonts.select_value(&settings.font.family);

        let mut app = Self {
            original: settings.clone(),
            paths,
            settings,
            tab: Tab::Themes,
            mode: Mode::Normal,
            themes,
            fonts,
            wallpapers: Picker::default(),
            look_cursor: 0,
            system_cursor: 0,
            pending_g: false,
            filter_anchor: None,
            preview_due: None,
            status: String::new(),
            show_help: false,
            pending_side_effect: None,
            graphics: None,
            preview: RefCell::new(None),
        };
        app.reload_wallpapers();
        Ok(app)
    }

    /// Re-read the wallpaper pool. It is a directory the user edits outside
    /// dotstyle, so the list is rebuilt on start rather than cached anywhere.
    pub fn reload_wallpapers(&mut self) {
        let names = crate::apply::wallpaper::list(&self.paths, &self.settings)
            .into_iter()
            .filter_map(|path| {
                path.file_name()
                    .map(|name| name.to_string_lossy().into_owned())
            })
            .collect();
        self.wallpapers = Picker::new(names);
        if !self.settings.wallpaper.current.is_empty() {
            let current = self.settings.wallpaper.current.clone();
            self.wallpapers.select_value(&current);
        }
    }

    /// The file behind the highlighted row on the Wallpaper tab.
    pub fn selected_wallpaper(&self) -> Option<PathBuf> {
        let name = self.wallpapers.selected()?;
        Some(crate::apply::wallpaper::directory(&self.paths, &self.settings).join(name))
    }

    /// Run `f` with the preview for `path`, decoding it first unless the cache
    /// already holds that exact file.
    ///
    /// The closure rather than a returned reference is what keeps the `RefCell`
    /// borrow from escaping into the draw code. It hands out `&mut` because a
    /// graphics protocol re-encodes the image when the pane changes size, and
    /// that bookkeeping lives in the protocol itself.
    pub fn with_preview<T>(
        &self,
        path: &Path,
        f: impl FnOnce(Result<&mut Preview, &str>) -> T,
    ) -> T {
        let mut slot = self.preview.borrow_mut();
        let stale = slot.as_ref().is_none_or(|cached| cached.path != path);
        if stale {
            *slot = Some(CachedPreview {
                path: path.to_path_buf(),
                result: Preview::load(path, self.graphics.as_ref())
                    .map_err(|error| format!("{error:#}")),
            });
        }

        let cached = slot.as_mut().expect("just populated");
        match &mut cached.result {
            Ok(preview) => f(Ok(preview)),
            Err(message) => f(Err(message)),
        }
    }

    pub fn active_picker(&self) -> Option<&Picker> {
        match self.tab {
            Tab::Themes => Some(&self.themes),
            Tab::Font => Some(&self.fonts),
            Tab::Wallpaper => Some(&self.wallpapers),
            Tab::Look | Tab::System => None,
        }
    }

    fn active_picker_mut(&mut self) -> Option<&mut Picker> {
        match self.tab {
            Tab::Themes => Some(&mut self.themes),
            Tab::Font => Some(&mut self.fonts),
            Tab::Wallpaper => Some(&mut self.wallpapers),
            Tab::Look | Tab::System => None,
        }
    }

    /// Push the highlighted row into `settings`. Returns whether anything moved.
    fn sync_selection(&mut self) -> bool {
        match self.tab {
            Tab::Themes => {
                let Some(theme) = self.themes.selected().map(str::to_string) else {
                    return false;
                };
                if theme == self.settings.theme {
                    return false;
                }
                self.settings.theme = theme;
                // The wallpaper is *not* cleared here. It used to be, because
                // the name referred to the old theme's own `backgrounds/`
                // directory; with one shared pool the picture you chose is
                // yours to keep across a theme switch.
                true
            }
            Tab::Font => {
                let Some(family) = self.fonts.selected().map(str::to_string) else {
                    return false;
                };
                if family == self.settings.font.family {
                    return false;
                }
                self.settings.font.family = family;
                true
            }
            Tab::Wallpaper => {
                let Some(name) = self.wallpapers.selected().map(str::to_string) else {
                    return false;
                };
                if name == self.settings.wallpaper.current {
                    return false;
                }
                self.settings.wallpaper.current = name;
                true
            }
            Tab::Look | Tab::System => false,
        }
    }

    pub fn look_field(&self) -> LookField {
        LookField::ALL[self.look_cursor.min(LookField::ALL.len() - 1)]
    }

    /// Nudge the highlighted Look field. Sizes are clamped to ranges that stay
    /// legible — a zero-height bar or a 200px border is never what was meant.
    fn adjust_look(&mut self, delta: i32) {
        let step = |value: u32, low: u32, high: u32| -> u32 {
            (value as i32 + delta).clamp(low as i32, high as i32) as u32
        };
        let field = self.look_field();
        let look = &mut self.settings.look;
        let font = &mut self.settings.font;

        match field {
            LookField::Gaps => look.gaps = step(look.gaps, 0, 64),
            LookField::BorderWidth => look.border_width = step(look.border_width, 0, 16),
            LookField::BarHeight => look.bar_height = step(look.bar_height, 14, 64),
            LookField::BarPosition => {
                look.bar_position = if look.bar_position == "top" {
                    "bottom".to_string()
                } else {
                    "top".to_string()
                };
            }
            LookField::FontSize => font.size = step(font.size, 6, 48),
            LookField::UiFontSize => font.ui_size = step(font.ui_size, 6, 32),
        }
    }

    pub fn system_row(&self) -> SystemRow {
        let rows = SystemRow::all();
        rows[self.system_cursor.min(rows.len() - 1)]
    }

    /// Value shown next to a System row.
    pub fn system_value(&self, row: SystemRow) -> String {
        let idle = &self.settings.idle;
        match row {
            SystemRow::Toggle(toggle) => {
                if toggles::is_on(toggle) { "on" } else { "off" }.to_string()
            }
            SystemRow::IdleEnabled => if idle.enabled { "on" } else { "off" }.to_string(),
            SystemRow::DimAfter => format_seconds(idle.dim_after),
            SystemRow::ScreensaverAfter => format_seconds(idle.screensaver_after),
            SystemRow::LockAfter => format_seconds(idle.lock_after),
            SystemRow::ScreenOffAfter => format_seconds(idle.screen_off_after),
            SystemRow::SuspendAfter => format_seconds(idle.suspend_after),
        }
    }

    /// Adjust the highlighted System row.
    ///
    /// Toggles take effect immediately and are not part of `settings`, so they
    /// are neither previewed nor reverted on quit — flipping do-not-disturb is
    /// an action, not a pending edit. The idle timings are settings, so they
    /// follow the usual preview/commit path.
    fn adjust_system(&mut self, delta: i32) -> Action {
        // A minute a step: seconds-granularity nudging through a 30-minute
        // suspend timeout would take 1800 keypresses.
        let step = |value: u32| -> u32 {
            (value as i32 + delta * 60).clamp(0, 7200) as u32
        };

        match self.system_row() {
            SystemRow::Toggle(toggle) => {
                match toggles::flip(toggle) {
                    Ok(on) => {
                        self.status = format!(
                            "{} {}",
                            toggle.label(),
                            if on { "on" } else { "off" }
                        );
                        self.pending_side_effect = Some(toggle);
                    }
                    Err(error) => self.status = format!("error: {error}"),
                }
                Action::None
            }
            SystemRow::IdleEnabled => {
                self.settings.idle.enabled = !self.settings.idle.enabled;
                Action::Preview
            }
            SystemRow::DimAfter => {
                self.settings.idle.dim_after = step(self.settings.idle.dim_after);
                Action::Preview
            }
            SystemRow::ScreensaverAfter => {
                self.settings.idle.screensaver_after =
                    step(self.settings.idle.screensaver_after);
                Action::Preview
            }
            SystemRow::LockAfter => {
                self.settings.idle.lock_after = step(self.settings.idle.lock_after);
                Action::Preview
            }
            SystemRow::ScreenOffAfter => {
                self.settings.idle.screen_off_after = step(self.settings.idle.screen_off_after);
                Action::Preview
            }
            SystemRow::SuspendAfter => {
                self.settings.idle.suspend_after = step(self.settings.idle.suspend_after);
                Action::Preview
            }
        }
    }

    /// Schedule a debounced preview.
    pub fn schedule_preview(&mut self) {
        self.preview_due = Some(Instant::now() + PREVIEW_DEBOUNCE);
    }

    /// How long the event loop may block before it must check for a due preview.
    pub fn poll_timeout(&self) -> Duration {
        if let Some(due) = self.preview_due {
            return due.saturating_duration_since(Instant::now());
        }
        // Otherwise wake only for a reason. The System tab reads the battery
        // and governor while drawing, so it wants a refresh; every other tab
        // is static between keypresses, and redrawing it four times a second
        // just gives the image protocol repeated chances to disturb graphics
        // the terminal has already painted.
        if self.tab == Tab::System {
            Duration::from_millis(250)
        } else {
            IDLE_POLL
        }
    }

    /// Whether a scheduled preview has come due, consuming the schedule.
    pub fn take_due_preview(&mut self) -> bool {
        match self.preview_due {
            Some(due) if Instant::now() >= due => {
                self.preview_due = None;
                true
            }
            _ => false,
        }
    }

    pub fn has_uncommitted_changes(&self) -> bool {
        self.settings != self.original
    }

    fn switch_tab(&mut self, delta: isize) {
        let count = Tab::ALL.len() as isize;
        let index = (self.tab.index() as isize + delta).rem_euclid(count);
        self.tab = Tab::ALL[index as usize];
    }

    /// The vim keymap. `half_page` is the visible row count / 2, which only the
    /// drawing layer knows.
    pub fn on_key(&mut self, key: Key, half_page: usize) -> Action {
        if self.mode == Mode::Filter {
            return self.on_filter_key(key);
        }

        // Any key other than a second `g` cancels a pending one.
        let pending_g = std::mem::take(&mut self.pending_g);
        if pending_g {
            if let Key::Char('g') = key {
                let moved = self.jump_cursor(false);
                return self.after_move(moved);
            }
        }

        match key {
            // `q` (and Ctrl-C, which is the terminal's own interrupt) is the
            // only way out. ⏎ saves and stays, so Esc quitting as well would
            // make an idle keypress throw away work that ⏎ had not yet kept.
            Key::Char('q') | Key::CtrlC => Action::Quit,
            Key::Esc => Action::None,
            Key::Enter => Action::Commit,
            Key::Char('?') => {
                self.show_help = !self.show_help;
                Action::None
            }
            Key::Char('g') => {
                self.pending_g = true;
                Action::None
            }
            Key::Char('G') => {
                let moved = self.jump_cursor(true);
                self.after_move(moved)
            }
            Key::Char('j') | Key::Down => self.move_by(1),
            Key::Char('k') | Key::Up => self.move_by(-1),
            Key::CtrlD | Key::PageDown => self.move_by(half_page.max(1) as isize),
            Key::CtrlU | Key::PageUp => self.move_by(-(half_page.max(1) as isize)),
            // On a list `h`/`l` change tab; on the Look tab there is no list, so
            // they do the thing the fields are actually for.
            Key::Char('l') | Key::Right => {
                if self.tab == Tab::Look {
                    self.adjust_look(1);
                    Action::Preview
                } else if self.tab == Tab::System {
                    self.adjust_system(1)
                } else {
                    self.switch_tab(1);
                    Action::None
                }
            }
            Key::Char('h') | Key::Left => {
                if self.tab == Tab::Look {
                    self.adjust_look(-1);
                    Action::Preview
                } else if self.tab == Tab::System {
                    self.adjust_system(-1)
                } else {
                    self.switch_tab(-1);
                    Action::None
                }
            }
            Key::Tab => {
                self.switch_tab(1);
                Action::None
            }
            Key::BackTab => {
                self.switch_tab(-1);
                Action::None
            }
            Key::Char(digit @ '1'..='5') => {
                let index = digit as usize - '1' as usize;
                self.tab = Tab::ALL[index];
                Action::None
            }
            Key::Char('/') => {
                if let Some(picker) = self.active_picker() {
                    self.filter_anchor = picker.selected().map(str::to_string);
                    self.mode = Mode::Filter;
                }
                Action::None
            }
            Key::Char('n') => self.move_by(1),
            Key::Char('N') => self.move_by(-1),
            _ => Action::None,
        }
    }

    fn on_filter_key(&mut self, key: Key) -> Action {
        match key {
            Key::Esc => {
                self.mode = Mode::Normal;
                let anchor = self.filter_anchor.take();
                if let Some(picker) = self.active_picker_mut() {
                    picker.set_query(String::new());
                    if let Some(anchor) = anchor {
                        picker.select_value(&anchor);
                    }
                }
                let moved = self.sync_selection();
                self.after_move(moved)
            }
            Key::Enter => {
                self.mode = Mode::Normal;
                self.filter_anchor = None;
                Action::None
            }
            Key::CtrlC => Action::Quit,
            Key::Backspace => {
                if let Some(picker) = self.active_picker_mut() {
                    picker.pop_query();
                }
                let moved = self.sync_selection();
                self.after_move(moved)
            }
            Key::Down => self.move_by(1),
            Key::Up => self.move_by(-1),
            Key::Char(character) => {
                if let Some(picker) = self.active_picker_mut() {
                    picker.push_query(character);
                }
                let moved = self.sync_selection();
                self.after_move(moved)
            }
            _ => Action::None,
        }
    }

    /// Row count of a tab that draws its own list instead of using a Picker.
    fn plain_list_len(&self) -> Option<usize> {
        match self.tab {
            Tab::Look => Some(LookField::ALL.len()),
            Tab::System => Some(SystemRow::all().len()),
            _ => None,
        }
    }

    fn plain_cursor_mut(&mut self) -> Option<&mut usize> {
        match self.tab {
            Tab::Look => Some(&mut self.look_cursor),
            Tab::System => Some(&mut self.system_cursor),
            _ => None,
        }
    }

    /// Move the cursor on whichever tab is active. Returns whether it moved.
    fn move_cursor(&mut self, delta: isize) -> bool {
        if let Some(length) = self.plain_list_len() {
            let last = (length - 1) as isize;
            let cursor = self.plain_cursor_mut().expect("plain tab has a cursor");
            let target = (*cursor as isize + delta).clamp(0, last) as usize;
            let moved = target != *cursor;
            *cursor = target;
            return moved;
        }
        self.active_picker_mut()
            .is_some_and(|picker| picker.step(delta))
    }

    fn jump_cursor(&mut self, to_end: bool) -> bool {
        if let Some(length) = self.plain_list_len() {
            let target = if to_end { length - 1 } else { 0 };
            let cursor = self.plain_cursor_mut().expect("plain tab has a cursor");
            let moved = target != *cursor;
            *cursor = target;
            return moved;
        }
        match self.active_picker_mut() {
            Some(picker) if to_end => picker.last(),
            Some(picker) => picker.jump(0),
            None => false,
        }
    }

    fn move_by(&mut self, delta: isize) -> Action {
        let moved = self.move_cursor(delta);
        self.after_move(moved)
    }

    /// Only a real change is worth a preview. Moving between Look *fields*
    /// changes nothing on screen, and holding `j` at the end of a list must not
    /// retint the desktop over and over.
    fn after_move(&mut self, moved: bool) -> Action {
        if !moved {
            return Action::None;
        }
        if !self.sync_selection() {
            return Action::None;
        }
        // A wallpaper does not reach swaybg until ⏎, so walking the list has
        // nothing to preview. Scheduling one anyway would reload sway and
        // retint every terminal for no visible change. The setting still moved,
        // so ⏎ saves it and `q` reverts it as usual.
        if self.tab == Tab::Wallpaper {
            return Action::None;
        }
        Action::Preview
    }
}

/// The key events the app understands, decoupled from crossterm so the keymap
/// can be tested directly.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Key {
    Char(char),
    Enter,
    Esc,
    Backspace,
    Tab,
    BackTab,
    Up,
    Down,
    Left,
    Right,
    PageUp,
    PageDown,
    CtrlC,
    CtrlD,
    CtrlU,
    Other,
}

#[cfg(test)]
pub(crate) mod tests_support {
    use super::*;
    use std::path::Path;

    pub fn app() -> App {
        let paths = Paths::from_dotfiles_root(
            Path::new(env!("CARGO_MANIFEST_DIR")).parent().unwrap(),
        );
        let settings = Settings {
            theme: "gruvbox".to_string(),
            ..Settings::default()
        };
        App::new(paths, settings).expect("building app")
    }
}

#[cfg(test)]
mod tests {
    use super::tests_support::app;
    use super::*;

    fn press(app: &mut App, keys: &[Key]) -> Action {
        let mut last = Action::None;
        for key in keys {
            last = app.on_key(*key, 5);
        }
        last
    }

    #[test]
    fn opens_on_the_active_theme() {
        let app = app();
        assert_eq!(app.themes.selected(), Some("gruvbox"));
    }

    #[test]
    fn jk_moves_and_previews() {
        let mut app = app();
        let before = app.themes.selected().unwrap().to_string();
        assert_eq!(press(&mut app, &[Key::Char('j')]), Action::Preview);
        assert_ne!(app.themes.selected().unwrap(), before);
        assert_eq!(app.settings.theme, app.themes.selected().unwrap());
    }

    #[test]
    fn gg_and_shift_g_jump_to_the_ends() {
        let mut app = app();
        press(&mut app, &[Key::Char('G')]);
        assert_eq!(app.themes.cursor(), app.themes.len() - 1);

        press(&mut app, &[Key::Char('g'), Key::Char('g')]);
        assert_eq!(app.themes.cursor(), 0);
    }

    #[test]
    fn a_lone_g_does_not_jump() {
        let mut app = app();
        press(&mut app, &[Key::Char('G')]);
        let bottom = app.themes.cursor();

        // `g` then something else must not behave like `gg`.
        press(&mut app, &[Key::Char('g'), Key::Char('k')]);
        assert_eq!(app.themes.cursor(), bottom - 1, "moved by k, not to the top");
    }

    #[test]
    fn ctrl_d_and_u_move_by_half_a_page() {
        let mut app = app();
        app.themes.jump(0);
        app.on_key(Key::CtrlD, 5);
        assert_eq!(app.themes.cursor(), 5);
        app.on_key(Key::CtrlU, 5);
        assert_eq!(app.themes.cursor(), 0);
    }

    #[test]
    fn hl_switch_tabs_but_adjust_fields_on_look() {
        let mut app = app();
        assert_eq!(app.tab, Tab::Themes);
        press(&mut app, &[Key::Char('l')]);
        assert_eq!(app.tab, Tab::Font);
        press(&mut app, &[Key::Char('h')]);
        assert_eq!(app.tab, Tab::Themes);

        app.tab = Tab::Look;
        let gaps = app.settings.look.gaps;
        assert_eq!(press(&mut app, &[Key::Char('l')]), Action::Preview);
        assert_eq!(app.settings.look.gaps, gaps + 1);
        press(&mut app, &[Key::Char('h'), Key::Char('h')]);
        assert_eq!(app.settings.look.gaps, gaps - 1);
        assert_eq!(app.tab, Tab::Look, "h/l never leave the Look tab");
    }

    #[test]
    fn look_values_are_clamped() {
        let mut app = app();
        app.tab = Tab::Look;
        app.look_cursor = 1; // border width
        for _ in 0..50 {
            app.on_key(Key::Char('h'), 5);
        }
        assert_eq!(app.settings.look.border_width, 0);
        for _ in 0..50 {
            app.on_key(Key::Char('l'), 5);
        }
        assert_eq!(app.settings.look.border_width, 16);
    }

    #[test]
    fn bar_position_toggles() {
        let mut app = app();
        app.tab = Tab::Look;
        app.look_cursor = 3;
        assert_eq!(app.settings.look.bar_position, "top");
        app.on_key(Key::Char('l'), 5);
        assert_eq!(app.settings.look.bar_position, "bottom");
        app.on_key(Key::Char('l'), 5);
        assert_eq!(app.settings.look.bar_position, "top");
    }

    #[test]
    fn filter_captures_navigation_keys() {
        let mut app = app();
        press(&mut app, &[Key::Char('/')]);
        assert_eq!(app.mode, Mode::Filter);

        // 'j' and 'k' are query text here, not movement.
        press(&mut app, &[Key::Char('k'), Key::Char('a'), Key::Char('n')]);
        assert_eq!(app.themes.query(), "kan");
        assert_eq!(app.themes.selected(), Some("kanagawa"));

        press(&mut app, &[Key::Enter]);
        assert_eq!(app.mode, Mode::Normal);
        assert_eq!(app.settings.theme, "kanagawa");
    }

    #[test]
    fn escaping_a_filter_clears_it() {
        let mut app = app();
        press(&mut app, &[Key::Char('/'), Key::Char('n'), Key::Char('o')]);
        assert!(app.themes.len() < app.themes.items().len());

        press(&mut app, &[Key::Esc]);
        assert_eq!(app.mode, Mode::Normal);
        assert_eq!(app.themes.query(), "");
        assert_eq!(app.themes.len(), app.themes.items().len());
    }

    #[test]
    fn filter_is_a_subsequence_match() {
        // Against a fixed list, not the live theme catalogue: "tkn" also
        // subsequence-matches names like "github-dark-colorblind", so a test
        // driven by whatever themes happen to be installed asserts the size of
        // the catalogue rather than the matching rule.
        let mut picker = Picker::new(vec![
            "gruvbox".to_string(),
            "tokyo-night".to_string(),
            "nord".to_string(),
        ]);
        picker.set_query("tkn".to_string());
        assert_eq!(picker.selected(), Some("tokyo-night"));
        assert_eq!(picker.len(), 1, "only tokyo-night contains t, k, n in order");
    }

    #[test]
    fn digits_jump_to_tabs() {
        let mut app = app();
        press(&mut app, &[Key::Char('3')]);
        assert_eq!(app.tab, Tab::Wallpaper);
        press(&mut app, &[Key::Char('1')]);
        assert_eq!(app.tab, Tab::Themes);
    }

    #[test]
    fn q_quits_and_enter_commits_without_quitting() {
        let mut app = app();
        assert_eq!(app.on_key(Key::Char('q'), 5), Action::Quit);
        assert_eq!(app.on_key(Key::CtrlC, 5), Action::Quit);
        assert_eq!(app.on_key(Key::Enter, 5), Action::Commit);
        // ⏎ is a save point, not an exit, so it can be pressed repeatedly.
        assert_eq!(app.on_key(Key::Enter, 5), Action::Commit);
    }

    #[test]
    fn moving_through_wallpapers_records_the_choice_without_previewing() {
        // The pane preview is drawn from the picker, not from the desktop, so
        // there is nothing for the event loop to do until the choice is saved.
        let mut app = app();
        app.wallpapers = Picker::new(vec!["one.png".to_string(), "two.png".to_string()]);
        app.tab = Tab::Wallpaper;
        app.settings.wallpaper.current = "one.png".to_string();
        app.original = app.settings.clone();

        assert_eq!(app.on_key(Key::Char('j'), 5), Action::None, "no desktop preview");
        assert_eq!(app.settings.wallpaper.current, "two.png", "but the choice moved");
        assert!(app.has_uncommitted_changes(), "so ⏎ has something to save");
    }

    #[test]
    fn esc_does_not_quit_from_normal_mode() {
        // With ⏎ saving in place rather than leaving, a stray Esc that quit
        // would discard whatever had not been saved yet.
        let mut app = app();
        assert_eq!(app.on_key(Key::Esc, 5), Action::None);
    }

    #[test]
    fn moving_past_the_end_does_not_re_preview() {
        let mut app = app();
        press(&mut app, &[Key::Char('G')]);
        assert_eq!(
            app.on_key(Key::Char('j'), 5),
            Action::None,
            "already at the bottom"
        );
    }

    #[test]
    fn changing_theme_keeps_the_wallpaper_choice() {
        // Wallpapers live in one shared pool now, so they are independent of
        // the theme. Clearing the choice here — which is what happened while
        // each theme carried its own `backgrounds/` — would throw away a
        // picture the user picked deliberately.
        let mut app = app();
        app.settings.wallpaper.current = "a-picture-i-like.jpg".to_string();
        press(&mut app, &[Key::Char('j')]);
        assert_eq!(app.settings.wallpaper.current, "a-picture-i-like.jpg");
    }

    #[test]
    fn tracks_uncommitted_changes() {
        let mut app = app();
        assert!(!app.has_uncommitted_changes());
        press(&mut app, &[Key::Char('j')]);
        assert!(app.has_uncommitted_changes());
    }

    #[test]
    fn debounce_defers_the_preview() {
        let mut app = app();
        app.schedule_preview();
        assert!(!app.take_due_preview(), "not due immediately");
        assert!(app.poll_timeout() <= PREVIEW_DEBOUNCE);
        std::thread::sleep(PREVIEW_DEBOUNCE + Duration::from_millis(20));
        assert!(app.take_due_preview(), "due after the debounce");
        assert!(!app.take_due_preview(), "and only fires once");
    }
}

#[cfg(test)]
mod ranking_tests {
    use super::*;

    #[test]
    fn ranks_prefix_above_substring_above_subsequence() {
        assert_eq!(match_score("kanagawa", "kan"), Some(0));
        assert_eq!(match_score("tokyo-kansas", "kan"), Some(1));
        assert_eq!(match_score("hackerman", "kan"), Some(2));
        assert_eq!(match_score("gruvbox", "kan"), None);
        assert_eq!(match_score("anything", ""), Some(0));
    }

    #[test]
    fn best_match_leads_the_list() {
        let mut picker = Picker::new(vec![
            "hackerman".to_string(),
            "kanagawa".to_string(),
            "nord".to_string(),
        ]);
        picker.set_query("kan".to_string());
        assert_eq!(picker.selected(), Some("kanagawa"));
        assert_eq!(picker.len(), 2, "hackerman still matches, just ranked lower");
    }
}

#[cfg(test)]
mod filter_undo_tests {
    use super::tests_support::app;
    use super::*;

    #[test]
    fn escape_restores_the_pre_filter_selection() {
        let mut app = app();
        assert_eq!(app.settings.theme, "gruvbox");

        app.on_key(Key::Char('/'), 5);
        for character in "nord".chars() {
            app.on_key(Key::Char(character), 5);
        }
        assert_eq!(app.settings.theme, "nord");

        app.on_key(Key::Esc, 5);
        assert_eq!(app.mode, Mode::Normal);
        assert_eq!(
            app.settings.theme, "gruvbox",
            "escaping a filter is an undo, not a jump to the top of the list"
        );
    }

    #[test]
    fn enter_keeps_the_filtered_choice() {
        let mut app = app();
        app.on_key(Key::Char('/'), 5);
        for character in "nord".chars() {
            app.on_key(Key::Char(character), 5);
        }
        app.on_key(Key::Enter, 5);
        assert_eq!(app.settings.theme, "nord");

        // And a later Esc must not undo a committed filter choice.
        app.on_key(Key::Esc, 5);
        assert_eq!(app.settings.theme, "nord");
    }
}

#[cfg(test)]
mod look_navigation_tests {
    use super::tests_support::app;
    use super::*;

    #[test]
    fn jk_moves_between_look_fields() {
        let mut app = app();
        app.tab = Tab::Look;
        assert_eq!(app.look_field(), LookField::Gaps);

        assert_eq!(
            app.on_key(Key::Char('j'), 5),
            Action::None,
            "moving between fields changes nothing to re-apply"
        );
        assert_eq!(app.look_field(), LookField::BorderWidth);

        app.on_key(Key::Char('j'), 5);
        assert_eq!(app.look_field(), LookField::BarHeight);
        app.on_key(Key::Char('k'), 5);
        assert_eq!(app.look_field(), LookField::BorderWidth);
    }

    #[test]
    fn adjusting_the_field_under_the_cursor_previews() {
        let mut app = app();
        app.tab = Tab::Look;
        app.on_key(Key::Char('j'), 5);
        app.on_key(Key::Char('j'), 5);
        assert_eq!(app.look_field(), LookField::BarHeight);

        let height = app.settings.look.bar_height;
        assert_eq!(app.on_key(Key::Char('l'), 5), Action::Preview);
        assert_eq!(app.settings.look.bar_height, height + 1);
        assert_eq!(app.settings.look.gaps, 16, "the wrong field was not touched");
    }

    #[test]
    fn gg_and_shift_g_work_on_look_too() {
        let mut app = app();
        app.tab = Tab::Look;
        app.on_key(Key::Char('G'), 5);
        assert_eq!(app.look_field(), LookField::UiFontSize);
        app.on_key(Key::Char('g'), 5);
        app.on_key(Key::Char('g'), 5);
        assert_eq!(app.look_field(), LookField::Gaps);
    }

    #[test]
    fn look_cursor_clamps_at_both_ends() {
        let mut app = app();
        app.tab = Tab::Look;
        for _ in 0..20 {
            app.on_key(Key::Char('k'), 5);
        }
        assert_eq!(app.look_field(), LookField::Gaps);
        for _ in 0..20 {
            app.on_key(Key::Char('j'), 5);
        }
        assert_eq!(app.look_field(), LookField::UiFontSize);
    }
}

impl App {
    /// One-line description of what the idle timeline will actually do, so the
    /// System tab shows the consequence of the numbers rather than only the
    /// numbers. Reflects stay-awake, which overrides the whole schedule.
    pub fn idle_summary(&self) -> String {
        if toggles::is_on(Toggle::StayAwake) {
            return "suppressed (stay awake)".to_string();
        }
        if !self.settings.idle.enabled {
            return "disabled".to_string();
        }

        let steps = crate::idle::steps(&self.settings, "dot-lock");
        if steps.is_empty() {
            return "no steps enabled".to_string();
        }

        steps
            .iter()
            .map(|step| {
                let what = match step.command.as_str() {
                    c if c.contains("set 10%") => "dim",
                    c if c.contains("dot-screensaver") => "screensaver",
                    c if c.contains("dot-lock") => "lock",
                    c if c.contains("power off") => "screen off",
                    c if c.contains("suspend") => "suspend",
                    _ => "step",
                };
                format!("{what} {}", format_seconds(step.after))
            })
            .collect::<Vec<_>>()
            .join(" → ")
    }
}

#[cfg(test)]
mod system_tab_tests {
    use super::tests_support::app;
    use super::*;

    /// Point toggle state at a scratch dir; the env var is process-wide, so
    /// these tests share a lock with the ones in `toggles`.
    fn with_scratch<T>(body: impl FnOnce() -> T) -> T {
        static LOCK: std::sync::Mutex<()> = std::sync::Mutex::new(());
        let guard = LOCK.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
        let directory = std::env::temp_dir().join(format!(
            "dotstyle-system-tab-{}-{:?}",
            std::process::id(),
            std::thread::current().id()
        ));
        std::fs::create_dir_all(&directory).unwrap();
        // SAFETY: the mutex serialises access to this process-wide variable.
        unsafe { std::env::set_var("DOTSTYLE_STATE_DIR", &directory) };
        let result = body();
        std::fs::remove_dir_all(&directory).ok();
        drop(guard);
        result
    }

    #[test]
    fn digit_five_reaches_the_new_tab() {
        let mut app = app();
        app.on_key(Key::Char('5'), 5);
        assert_eq!(app.tab, Tab::System);
    }

    #[test]
    fn jk_walks_toggles_then_the_idle_timeline() {
        let mut app = app();
        app.tab = Tab::System;
        assert!(matches!(app.system_row(), SystemRow::Toggle(Toggle::Dnd)));

        for _ in 0..Toggle::ALL.len() {
            app.on_key(Key::Char('j'), 5);
        }
        assert_eq!(app.system_row(), SystemRow::IdleEnabled);

        app.on_key(Key::Char('G'), 5);
        assert_eq!(app.system_row(), SystemRow::SuspendAfter);
    }

    #[test]
    fn idle_timings_step_by_the_minute_and_clamp() {
        let mut app = app();
        app.tab = Tab::System;
        app.on_key(Key::Char('G'), 5);
        assert_eq!(app.system_row(), SystemRow::SuspendAfter);

        let before = app.settings.idle.suspend_after;
        assert_eq!(app.on_key(Key::Char('l'), 5), Action::Preview);
        assert_eq!(app.settings.idle.suspend_after, before + 60);

        for _ in 0..500 {
            app.on_key(Key::Char('h'), 5);
        }
        assert_eq!(app.settings.idle.suspend_after, 0, "clamps at off");
    }

    #[test]
    fn toggles_take_effect_immediately_and_are_not_pending_edits() {
        with_scratch(|| {
            let mut app = app();
            app.tab = Tab::System;
            assert!(matches!(app.system_row(), SystemRow::Toggle(Toggle::Dnd)));

            let action = app.on_key(Key::Char('l'), 5);
            assert_eq!(action, Action::None, "a toggle is an action, not a preview");
            assert!(toggles::is_on(Toggle::Dnd), "flipped for real");
            assert_eq!(app.pending_side_effect, Some(Toggle::Dnd));
            assert!(
                !app.has_uncommitted_changes(),
                "toggles are session state, so quitting must not revert them"
            );
        });
    }

    #[test]
    fn idle_summary_reads_as_a_sequence() {
        with_scratch(|| {
            let app = app();
            let summary = app.idle_summary();
            assert!(summary.contains("dim 4 min"), "{summary}");
        assert!(summary.contains("screensaver"), "{summary}");
            assert!(summary.contains("lock 6 min"), "{summary}");
            assert!(summary.contains("suspend 30 min"), "{summary}");
            assert!(summary.contains('→'), "{summary}");
        });
    }

    #[test]
    fn stay_awake_overrides_the_whole_summary() {
        with_scratch(|| {
            let app = app();
            toggles::set(Toggle::StayAwake, true).unwrap();
            assert_eq!(app.idle_summary(), "suppressed (stay awake)");
        });
    }

    #[test]
    fn disabling_idle_says_so() {
        with_scratch(|| {
            let mut app = app();
            app.settings.idle.enabled = false;
            assert_eq!(app.idle_summary(), "disabled");
        });
    }

    #[test]
    fn seconds_are_formatted_for_humans() {
        assert_eq!(format_seconds(0), "off");
        assert_eq!(format_seconds(45), "45 s");
        assert_eq!(format_seconds(60), "1 min");
        assert_eq!(format_seconds(1800), "30 min");
        assert_eq!(format_seconds(90), "90 s");
    }
}
