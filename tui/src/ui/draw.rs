//! Rendering the TUI.
//!
//! The right-hand pane always shows the theme as it will look, painted in the
//! theme's own colors, so the preview reads correctly even before the debounced
//! apply reaches the rest of the desktop.

use ratatui::layout::{Alignment, Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Clear, List, ListItem, ListState, Paragraph, Tabs, Wrap};
use ratatui::Frame;

use crate::color::parse_hex;
use crate::palette::Palette;

use super::app::{App, LookField, Mode, SystemRow, Tab};

/// Rows of list visible in the picker pane, for `Ctrl-d` / `Ctrl-u`.
pub fn half_page(area: Rect) -> usize {
    // Two rows of border, one of tabs, one of status.
    (area.height.saturating_sub(6) / 2).max(1) as usize
}

fn rgb(palette: &Palette, key: &str) -> Color {
    palette
        .get(key)
        .and_then(parse_hex)
        .map(|(r, g, b)| Color::Rgb(r, g, b))
        .unwrap_or(Color::Reset)
}

pub fn draw(frame: &mut Frame, app: &App, palette: &Palette) {
    let area = frame.area();
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(6),
            Constraint::Length(1),
        ])
        .split(area);

    draw_tabs(frame, chunks[0], app, palette);

    let panes = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(40), Constraint::Percentage(60)])
        .split(chunks[1]);

    match app.tab {
        Tab::Look => draw_look(frame, panes[0], app, palette),
        Tab::System => draw_system(frame, panes[0], app, palette),
        _ => draw_picker(frame, panes[0], app, palette),
    }
    draw_preview(frame, panes[1], app, palette);
    draw_status(frame, chunks[2], app, palette);

    if app.show_help {
        draw_help(frame, area, palette);
    }
}

fn draw_tabs(frame: &mut Frame, area: Rect, app: &App, palette: &Palette) {
    let titles: Vec<Line> = Tab::ALL
        .iter()
        .enumerate()
        .map(|(index, tab)| {
            Line::from(vec![
                Span::styled(
                    format!(" {} ", index + 1),
                    Style::default().fg(rgb(palette, "muted")),
                ),
                Span::raw(tab.title()),
            ])
        })
        .collect();

    let selected = Tab::ALL.iter().position(|t| *t == app.tab).unwrap_or(0);
    let tabs = Tabs::new(titles)
        .select(selected)
        .style(Style::default().fg(rgb(palette, "foreground")))
        .highlight_style(
            Style::default()
                .fg(rgb(palette, "accent"))
                .add_modifier(Modifier::BOLD),
        )
        .divider(Span::styled(
            "│",
            Style::default().fg(rgb(palette, "muted")),
        ))
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(Style::default().fg(rgb(palette, "muted")))
                .title(Span::styled(
                    " dotstyle ",
                    Style::default()
                        .fg(rgb(palette, "accent"))
                        .add_modifier(Modifier::BOLD),
                )),
        );
    frame.render_widget(tabs, area);
}

fn draw_picker(frame: &mut Frame, area: Rect, app: &App, palette: &Palette) {
    let Some(picker) = app.active_picker() else {
        return;
    };

    let items: Vec<ListItem> = picker
        .visible()
        .map(|(_, name)| ListItem::new(Line::from(format!("  {name}"))))
        .collect();

    let title = if app.mode == Mode::Filter || !picker.query().is_empty() {
        format!(" /{} ({}) ", picker.query(), picker.len())
    } else {
        format!(" {} ({}) ", app.tab.title(), picker.len())
    };

    let list = List::new(items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(Style::default().fg(rgb(palette, "muted")))
                .title(Span::styled(
                    title,
                    Style::default().fg(rgb(palette, "accent")),
                )),
        )
        .style(Style::default().fg(rgb(palette, "foreground")))
        .highlight_style(
            Style::default()
                .bg(rgb(palette, "accent"))
                .fg(rgb(palette, "background"))
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol("▌ ");

    let mut state = ListState::default();
    if !picker.is_empty() {
        state.select(Some(picker.cursor()));
    }
    frame.render_stateful_widget(list, area, &mut state);
}

fn draw_look(frame: &mut Frame, area: Rect, app: &App, palette: &Palette) {
    let settings = &app.settings;
    let value = |field: LookField| -> String {
        match field {
            LookField::Gaps => settings.look.gaps.to_string(),
            LookField::BorderWidth => settings.look.border_width.to_string(),
            LookField::BarHeight => settings.look.bar_height.to_string(),
            LookField::BarPosition => settings.look.bar_position.clone(),
            LookField::FontSize => settings.font.size.to_string(),
            LookField::UiFontSize => settings.font.ui_size.to_string(),
        }
    };

    let items: Vec<ListItem> = LookField::ALL
        .iter()
        .map(|field| {
            ListItem::new(Line::from(vec![
                Span::raw(format!("  {:<20}", field.label())),
                Span::styled(
                    format!("‹ {} ›", value(*field)),
                    Style::default().fg(rgb(palette, "accent")),
                ),
            ]))
        })
        .collect();

    let list = List::new(items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(Style::default().fg(rgb(palette, "muted")))
                .title(Span::styled(
                    " Look — h/l adjusts ",
                    Style::default().fg(rgb(palette, "accent")),
                )),
        )
        .style(Style::default().fg(rgb(palette, "foreground")))
        .highlight_style(
            Style::default()
                .bg(rgb(palette, "lighter_background"))
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol("▌ ");

    let mut state = ListState::default();
    state.select(Some(app.look_cursor));
    frame.render_stateful_widget(list, area, &mut state);
}

fn draw_system(frame: &mut Frame, area: Rect, app: &App, palette: &Palette) {
    let rows = SystemRow::all();
    let mut items: Vec<ListItem> = Vec::with_capacity(rows.len() + 1);

    for (index, row) in rows.iter().enumerate() {
        // The toggles and the idle timeline are different kinds of thing —
        // one acts now, one is a pending setting — so they get a divider
        // rather than running together as one undifferentiated list.
        if *row == SystemRow::IdleEnabled && index > 0 {
            items.push(ListItem::new(Line::from(Span::styled(
                "  ── idle timeline ─────────────────────",
                Style::default().fg(rgb(palette, "muted")),
            ))));
        }

        let value = app.system_value(*row);
        let value_color = match row {
            SystemRow::Toggle(_) if value == "on" => rgb(palette, "green"),
            SystemRow::Toggle(_) => rgb(palette, "dark_foreground"),
            _ if value == "off" => rgb(palette, "dark_foreground"),
            _ => rgb(palette, "accent"),
        };

        items.push(ListItem::new(Line::from(vec![
            Span::raw(format!("  {:<20}", row.label())),
            Span::styled(format!("‹ {value} ›"), Style::default().fg(value_color)),
        ])));
    }

    let list = List::new(items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(Style::default().fg(rgb(palette, "muted")))
                .title(Span::styled(
                    " System — h/l toggles & adjusts ",
                    Style::default().fg(rgb(palette, "accent")),
                )),
        )
        .style(Style::default().fg(rgb(palette, "foreground")))
        .highlight_style(
            Style::default()
                .bg(rgb(palette, "lighter_background"))
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol("▌ ");

    // The divider occupies a row, so the visual index runs ahead of the
    // logical one once the cursor passes it.
    let divider_offset = usize::from(app.system_cursor >= Toggle_count());
    let mut state = ListState::default();
    state.select(Some(app.system_cursor + divider_offset));
    frame.render_stateful_widget(list, area, &mut state);
}

/// How many rows precede the idle divider.
#[allow(non_snake_case)]
fn Toggle_count() -> usize {
    SystemRow::all()
        .iter()
        .take_while(|row| matches!(row, SystemRow::Toggle(_)))
        .count()
}

fn draw_preview(frame: &mut Frame, area: Rect, app: &App, palette: &Palette) {
    // On the Wallpaper tab the picture is the preview; the palette mock below
    // is about the theme, which the Themes tab is already showing.
    let title = if app.tab == Tab::Wallpaper {
        app.wallpapers.selected().unwrap_or("wallpaper").to_string()
    } else {
        app.settings.theme.clone()
    };

    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(rgb(palette, "accent")))
        .title(Span::styled(
            format!(" {title} "),
            Style::default()
                .fg(rgb(palette, "accent"))
                .add_modifier(Modifier::BOLD),
        ))
        .style(Style::default().bg(rgb(palette, "background")));

    let inner = block.inner(area);
    frame.render_widget(block, area);

    if app.tab == Tab::Wallpaper {
        draw_wallpaper(frame, inner, app, palette);
        return;
    }

    let mut lines: Vec<Line> = Vec::new();

    // A mock bar and window frame, drawn in the colors sway is about to use.
    lines.push(Line::from(vec![
        Span::styled(
            " 1 ",
            Style::default()
                .bg(rgb(palette, "accent"))
                .fg(rgb(palette, "background"))
                .add_modifier(Modifier::BOLD),
        ),
        Span::styled(
            " 2  3 ",
            Style::default()
                .bg(rgb(palette, "lighter_background"))
                .fg(rgb(palette, "dark_foreground")),
        ),
        Span::styled(
            format!("{:>18}", "12:04  ▁▃▅  85% "),
            Style::default()
                .bg(rgb(palette, "background"))
                .fg(rgb(palette, "foreground")),
        ),
    ]));
    lines.push(Line::from(Span::styled(
        "─".repeat(inner.width as usize),
        Style::default().fg(rgb(palette, "muted")),
    )));

    // A shell transcript, so the ANSI slots are shown doing their real job.
    lines.push(Line::from(vec![
        Span::styled("~/workspace ", Style::default().fg(rgb(palette, "yellow"))),
        Span::styled("(main) ", Style::default().fg(rgb(palette, "magenta"))),
        Span::styled("$ ", Style::default().fg(rgb(palette, "green"))),
        Span::styled(
            "cargo test",
            Style::default().fg(rgb(palette, "foreground")),
        ),
    ]));
    lines.push(Line::from(vec![
        Span::styled("   ok", Style::default().fg(rgb(palette, "bright_green"))),
        Span::styled(
            "  41 passed  ",
            Style::default().fg(rgb(palette, "foreground")),
        ),
        Span::styled(
            "0 failed",
            Style::default().fg(rgb(palette, "dark_foreground")),
        ),
    ]));
    lines.push(Line::from(vec![
        Span::styled("   error", Style::default().fg(rgb(palette, "red"))),
        Span::styled(
            ": unresolved ",
            Style::default().fg(rgb(palette, "foreground")),
        ),
        Span::styled("{{ token }}", Style::default().fg(rgb(palette, "cyan"))),
    ]));
    lines.push(Line::from(""));

    // The palette itself: ANSI row, then the semantic roles.
    lines.push(swatch_row(palette, (0..8).map(|i| format!("color{i}"))));
    lines.push(swatch_row(palette, (8..16).map(|i| format!("color{i}"))));
    lines.push(Line::from(""));

    for (label, key) in [
        ("accent", "accent"),
        ("background", "background"),
        ("foreground", "foreground"),
        ("muted", "muted"),
        ("selection", "selection_background"),
    ] {
        let value = palette.get(key).unwrap_or("—");
        lines.push(Line::from(vec![
            Span::styled("  ██ ", Style::default().fg(rgb(palette, key))),
            Span::styled(
                format!("{label:<12}"),
                Style::default().fg(rgb(palette, "dark_foreground")),
            ),
            Span::styled(
                value.to_string(),
                Style::default().fg(rgb(palette, "foreground")),
            ),
        ]));
    }

    lines.push(Line::from(""));
    lines.push(Line::from(vec![
        Span::styled(
            "  mode ",
            Style::default().fg(rgb(palette, "dark_foreground")),
        ),
        Span::styled(
            palette.get("mode").unwrap_or("dark").to_string(),
            Style::default().fg(rgb(palette, "foreground")),
        ),
        Span::styled(
            "   font ",
            Style::default().fg(rgb(palette, "dark_foreground")),
        ),
        Span::styled(
            format!("{} {}pt", app.settings.font.family, app.settings.font.size),
            Style::default().fg(rgb(palette, "foreground")),
        ),
    ]));

    if app.tab == Tab::System {
        lines.push(Line::from(vec![
            Span::styled(
                "  idle ",
                Style::default().fg(rgb(palette, "dark_foreground")),
            ),
            Span::styled(
                app.idle_summary(),
                Style::default().fg(rgb(palette, "foreground")),
            ),
        ]));
        lines.push(Line::from(vec![
            Span::styled(
                "  hw   ",
                Style::default().fg(rgb(palette, "dark_foreground")),
            ),
            Span::styled(
                crate::hardware::Hardware::read().summary(),
                Style::default().fg(rgb(palette, "foreground")),
            ),
        ]));
        // Changing these needs pkexec or sudo, and a password prompt over a
        // full-screen TUI corrupts the display. Point at the command instead.
        lines.push(Line::from(Span::styled(
            "       change with: dot-power | dot-kbd-backlight",
            Style::default().fg(rgb(palette, "muted")),
        )));
    }

    frame.render_widget(
        Paragraph::new(lines)
            .wrap(Wrap { trim: false })
            .style(Style::default().bg(rgb(palette, "background"))),
        inner,
    );
}

/// The highlighted wallpaper, drawn as half-blocks with a caption under it.
fn draw_wallpaper(frame: &mut Frame, area: Rect, app: &App, palette: &Palette) {
    let backdrop = rgb(palette, "background");
    let Some(path) = app.selected_wallpaper() else {
        let directory = crate::apply::wallpaper::directory(&app.paths, &app.settings);
        frame.render_widget(
            Paragraph::new(vec![
                Line::from(Span::styled(
                    "  no images in",
                    Style::default().fg(rgb(palette, "dark_foreground")),
                )),
                Line::from(Span::styled(
                    format!("  {}", directory.display()),
                    Style::default().fg(rgb(palette, "muted")),
                )),
            ])
            .style(Style::default().bg(backdrop)),
            area,
        );
        return;
    };

    // One row is kept back for the caption, which is where the file's real
    // dimensions go — the preview is resampled, so its own size says nothing.
    let caption_height = 1;
    let picture = Rect {
        height: area.height.saturating_sub(caption_height),
        ..area
    };

    // Prefer the size the graphics protocol negotiated: it is what the terminal
    // will actually use to place the image, and it can differ from what
    // TIOCGWINSZ reports.
    let cell = app
        .graphics
        .as_ref()
        .map(|picker| picker.font_size())
        .or_else(crate::ui::preview::cell_pixels);
    let picture = crate::ui::preview::clamp(picture, cell);

    let caption = app.with_preview(&path, |preview| match preview {
        Ok(preview) => {
            let (width, height) = preview.source;
            // Wipe the pane the first time a new picture is drawn, so whatever
            // the previous one left outside the new one's bounds is written
            // over and the terminal drops the graphic there. Painted with the
            // theme background rather than `Clear`, which would strip the
            // pane's own colour along with the residue.
            if preview.take_fresh() {
                frame.render_widget(
                    Block::default().style(Style::default().bg(backdrop)),
                    picture,
                );
            }

            let failure = preview
                .draw(frame, picture)
                .err()
                .map(|error| format!("{error:#}"));

            match failure {
                Some(message) => Line::from(Span::styled(
                    format!(" {message}"),
                    Style::default().fg(rgb(palette, "red")),
                )),
                None => Line::from(vec![
                    Span::styled(
                        format!(" {width}x{height}"),
                        Style::default().fg(rgb(palette, "foreground")),
                    ),
                    Span::styled(
                        format!("  mode {}", app.settings.wallpaper.mode),
                        Style::default().fg(rgb(palette, "dark_foreground")),
                    ),
                ]),
            }
        }
        Err(message) => {
            frame.render_widget(
                Paragraph::new(Line::from(Span::styled(
                    format!("  {message}"),
                    Style::default().fg(rgb(palette, "red")),
                )))
                .wrap(Wrap { trim: false })
                .style(Style::default().bg(backdrop)),
                picture,
            );
            Line::from(Span::styled(
                " not previewable",
                Style::default().fg(rgb(palette, "red")),
            ))
        }
    });

    if area.height >= caption_height {
        frame.render_widget(
            Paragraph::new(caption).style(Style::default().bg(backdrop)),
            Rect {
                y: area.y + area.height - caption_height,
                height: caption_height,
                ..area
            },
        );
    }
}

fn swatch_row(palette: &Palette, keys: impl Iterator<Item = String>) -> Line<'static> {
    let mut spans = vec![Span::raw("  ")];
    for key in keys {
        spans.push(Span::styled("███", Style::default().fg(rgb(palette, &key))));
        spans.push(Span::raw(" "));
    }
    Line::from(spans)
}

fn draw_status(frame: &mut Frame, area: Rect, app: &App, palette: &Palette) {
    let hint = if app.mode == Mode::Filter {
        "type to filter   ⏎ accept   esc cancel"
    } else {
        "j/k move   h/l tab   gg/G ends   / filter   ⏎ save   q revert & quit   ? help"
    };

    let mut spans = vec![Span::styled(
        format!(" {hint} "),
        Style::default().fg(rgb(palette, "dark_foreground")),
    )];

    if !app.status.is_empty() {
        spans.push(Span::styled(
            format!("· {} ", app.status),
            Style::default().fg(rgb(palette, "green")),
        ));
    }
    if app.has_uncommitted_changes() {
        spans.push(Span::styled(
            "· unsaved ",
            Style::default().fg(rgb(palette, "yellow")),
        ));
    }

    frame.render_widget(
        Paragraph::new(Line::from(spans)).style(Style::default().bg(rgb(palette, "background"))),
        area,
    );
}

fn draw_help(frame: &mut Frame, area: Rect, palette: &Palette) {
    let width = 52.min(area.width.saturating_sub(4));
    let height = 18.min(area.height.saturating_sub(4));
    let popup = Rect {
        x: area.x + (area.width - width) / 2,
        y: area.y + (area.height - height) / 2,
        width,
        height,
    };

    let rows = [
        ("j / k", "move down / up"),
        ("h / l", "prev / next tab · adjust on Look"),
        ("gg / G", "first / last item"),
        ("Ctrl-d / Ctrl-u", "half page down / up"),
        ("/", "filter; esc undoes, ⏎ accepts"),
        ("n / N", "next / previous match"),
        ("1–5", "jump to a tab"),
        ("⏎", "save to theme/settings.toml and stay"),
        ("q", "revert anything unsaved and quit"),
        ("?", "close this help"),
    ];

    let mut lines = vec![Line::from("")];
    for (keys, description) in rows {
        lines.push(Line::from(vec![
            Span::styled(
                format!("  {keys:<16}"),
                Style::default()
                    .fg(rgb(palette, "accent"))
                    .add_modifier(Modifier::BOLD),
            ),
            Span::styled(description, Style::default().fg(rgb(palette, "foreground"))),
        ]));
    }

    frame.render_widget(Clear, popup);
    frame.render_widget(
        Paragraph::new(lines)
            .alignment(Alignment::Left)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .border_style(Style::default().fg(rgb(palette, "accent")))
                    .title(Span::styled(
                        " keys ",
                        Style::default().fg(rgb(palette, "accent")),
                    )),
            )
            .style(Style::default().bg(rgb(palette, "dark_background"))),
        popup,
    );
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::paths::Paths;
    use crate::settings::Settings;
    use ratatui::backend::TestBackend;
    use ratatui::Terminal;
    use std::path::PathBuf;

    /// A scratch dotfiles root with one theme and one real image, so the whole
    /// draw path can run — the geometry here (letterboxing, the caption row)
    /// is the part worth checking, and it is invisible from a unit test of the
    /// thumbnail alone.
    struct Fixture {
        root: PathBuf,
        app: App,
        palette: Palette,
    }

    impl Fixture {
        fn new(image_size: (u32, u32)) -> Self {
            let root = std::env::temp_dir().join(format!(
                "dotstyle-draw-{}-{:?}",
                std::process::id(),
                std::thread::current().id()
            ));
            let theme = root.join("theme/themes/probe");
            std::fs::create_dir_all(&theme).unwrap();
            std::fs::write(
                theme.join("colors.toml"),
                "background = \"#101010\"\nforeground = \"#eeeeee\"\naccent = \"#7aa2f7\"\n",
            )
            .unwrap();

            let pool = root.join("wallpapers");
            std::fs::create_dir_all(&pool).unwrap();
            let (width, height) = image_size;
            // A gradient rather than a flat fill: ratatui-image emits a space
            // when a cell's two halves match, so a solid image would exercise
            // none of the glyph path.
            let data: Vec<u8> = (0..height)
                .flat_map(|y| {
                    (0..width)
                        .flat_map(move |x| [(x * 255 / width) as u8, (y * 255 / height) as u8, 90])
                })
                .collect();
            image::save_buffer(
                pool.join("picture.png"),
                &data,
                width,
                height,
                image::ExtendedColorType::Rgb8,
            )
            .unwrap();

            let paths = Paths::from_dotfiles_root(&root);
            let settings = Settings {
                theme: "probe".to_string(),
                wallpaper: crate::settings::Wallpaper {
                    dir: "wallpapers".to_string(),
                    ..Default::default()
                },
                ..Settings::default()
            };
            let palette = Palette::load(&paths.colors_file("probe")).unwrap();
            let mut app = App::new(paths, settings).unwrap();
            app.tab = Tab::Wallpaper;

            Self { root, app, palette }
        }

        /// Render one frame and hand back the buffer.
        fn frame(&self, width: u16, height: u16) -> ratatui::buffer::Buffer {
            let mut terminal = Terminal::new(TestBackend::new(width, height)).unwrap();
            terminal
                .draw(|f| draw(f, &self.app, &self.palette))
                .unwrap();
            terminal.backend().buffer().clone()
        }
    }

    impl Drop for Fixture {
        fn drop(&mut self) {
            std::fs::remove_dir_all(&self.root).ok();
        }
    }

    fn cells(buffer: &ratatui::buffer::Buffer) -> impl Iterator<Item = &ratatui::buffer::Cell> {
        buffer.content().iter()
    }

    #[test]
    fn the_wallpaper_tab_draws_the_picture() {
        let fixture = Fixture::new((600, 400));
        let buffer = fixture.frame(80, 24);

        // Under test there is no terminal to query, so the preview falls back
        // to ratatui-image's half-blocks. Colour is the thing to assert on
        // rather than the glyph: a cell whose two halves match is emitted as a
        // space carrying the colour in its background.
        // Colour is the thing to assert on rather than the glyph: a cell whose
        // two halves match is emitted as a space carrying the colour in its
        // background. Blue is constant across the fixture, so it survives
        // resampling and marks every cell the picture reached.
        let painted = cells(&buffer)
            .filter(|cell| {
                matches!(cell.bg, Color::Rgb(_, _, 90)) || matches!(cell.fg, Color::Rgb(_, _, 90))
            })
            .count();
        assert!(
            painted > 400,
            "expected the image to fill much of the pane, got {painted} cells"
        );
    }

    #[test]
    fn the_wallpaper_tab_captions_the_file_size() {
        let fixture = Fixture::new((600, 400));
        let buffer = fixture.frame(80, 24);

        let text: String = cells(&buffer).map(|cell| cell.symbol()).collect();
        assert!(
            text.contains("600x400"),
            "the file's own dimensions are the caption"
        );
        assert!(
            text.contains("picture.png"),
            "the name belongs in the title"
        );
    }

    #[test]
    fn a_pane_too_small_for_a_picture_still_draws() {
        // Terminals get resized to absurd sizes mid-session; the geometry must
        // degrade rather than panic on a zero-height picture area.
        let fixture = Fixture::new((600, 400));
        for height in [3, 4, 5, 6] {
            fixture.frame(20, height);
        }
    }

    #[test]
    fn the_other_tabs_still_draw_the_palette_mock() {
        let mut fixture = Fixture::new((60, 40));
        fixture.app.tab = Tab::Themes;
        let buffer = fixture.frame(80, 24);

        let text: String = cells(&buffer).map(|cell| cell.symbol()).collect();
        assert!(
            text.contains("cargo test"),
            "the shell transcript mock is gone"
        );
        assert!(
            !text.contains("600x400"),
            "the wallpaper caption leaked onto Themes"
        );
    }
}
