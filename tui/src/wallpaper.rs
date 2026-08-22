//! Generating a wallpaper from a theme's palette.
//!
//! Most themes have no artwork — the ones imported from alacritty palettes are
//! colours and nothing else. Rather than hunt down an image per theme, the
//! wallpaper is derived from the palette itself, so it always matches, needs no
//! network, and carries no licensing question.
//!
//! The look is a "mesh gradient": a handful of colour points scattered over the
//! canvas, each pixel taking a distance-weighted blend of them. It stays soft
//! and low-contrast on purpose — a wallpaper sits *behind* windows, and
//! anything busy makes the desktop harder to read, not nicer.
//!
//! There is deliberately **no dithering**, which is worth recording because it
//! is the obvious thing to reach for with gradients this smooth. Measured on a
//! light theme at 1920x1200: no dither is 116K and shows no banding worth
//! seeing at native scale; an ordered `(x ^ y) & 3` pattern is 512K and its
//! crosshatch weave is *more* visible than the banding it removes; per-pixel
//! noise is 1.3M because it is incompressible. Across 142 themes that is 16MB
//! against 155MB, for a worse-looking result.

use std::path::Path;

use anyhow::{Context, Result};

use crate::color::parse_hex;
use crate::palette::Palette;

pub const DEFAULT_WIDTH: u32 = 1920;
pub const DEFAULT_HEIGHT: u32 = 1200;

/// How far each accent is pulled toward the background before blending.
/// Higher is more muted; at 0 the accents are full strength and the result is
/// far too loud to sit behind a terminal. At 0.72 they all but vanish and every
/// theme produces the same flat wash, so this sits in between.
const MUTE: f64 = 0.55;

/// How much the edges darken. A slight vignette gives the field a centre and
/// keeps the corners from competing with panels and window edges.
const VIGNETTE: f64 = 0.12;

struct Point {
    x: f64,
    y: f64,
    rgb: (f64, f64, f64),
    /// Squared falloff distance. Varying it per point is what keeps the field
    /// from looking like one uniform blur — some accents read as a tight glow,
    /// others as a broad wash.
    falloff: f64,
}

/// Deterministic PRNG, so a theme's wallpaper is identical every time it is
/// generated. These files are gitignored and regenerated on a fresh machine,
/// which only works if generation is reproducible.
struct Rng(u64);

impl Rng {
    fn from_seed(seed: &str) -> Self {
        // FNV-1a: tiny, and good enough to scatter points from a name.
        let mut hash: u64 = 0xcbf2_9ce4_8422_2325;
        for byte in seed.as_bytes() {
            hash ^= u64::from(*byte);
            hash = hash.wrapping_mul(0x0000_0100_0000_01b3);
        }
        Self(hash | 1)
    }

    /// xorshift64*
    fn next_u64(&mut self) -> u64 {
        let mut x = self.0;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        self.0 = x;
        x.wrapping_mul(0x2545_F491_4F6C_DD1D)
    }

    fn next_f64(&mut self) -> f64 {
        (self.next_u64() >> 11) as f64 / (1u64 << 53) as f64
    }

    fn range(&mut self, low: f64, high: f64) -> f64 {
        low + self.next_f64() * (high - low)
    }
}

fn to_f64(hex: &str) -> Option<(f64, f64, f64)> {
    let (r, g, b) = parse_hex(hex)?;
    Some((f64::from(r), f64::from(g), f64::from(b)))
}

/// Pull a colour toward the background, so accents read as a tint rather than
/// a block of colour.
fn mute(color: (f64, f64, f64), background: (f64, f64, f64)) -> (f64, f64, f64) {
    (
        color.0 * (1.0 - MUTE) + background.0 * MUTE,
        color.1 * (1.0 - MUTE) + background.1 * MUTE,
        color.2 * (1.0 - MUTE) + background.2 * MUTE,
    )
}

/// Render the wallpaper as raw RGB bytes.
pub fn render(palette: &Palette, seed: &str, width: u32, height: u32) -> Result<Vec<u8>> {
    let background = palette
        .get("background")
        .and_then(to_f64)
        .context("theme has no background colour")?;

    // Fixed order, so the choice never depends on hash iteration order.
    let accent_keys = [
        "accent", "blue", "magenta", "cyan", "green", "orange", "red", "yellow",
    ];
    let mut rng = Rng::from_seed(seed);

    let mut points: Vec<Point> = Vec::new();
    for key in accent_keys {
        let Some(color) = palette.get(key).and_then(to_f64) else {
            continue;
        };
        let radius = rng.range(0.18, 0.46) * f64::from(width);
        points.push(Point {
            // Keep points off the extreme edges: a blob centred in a corner
            // shows only a quarter of itself and reads as a smudge.
            x: rng.range(0.08, 0.92) * f64::from(width),
            y: rng.range(0.08, 0.92) * f64::from(height),
            rgb: mute(color, background),
            falloff: radius * radius,
        });
    }

    // A couple of background-coloured points give the field somewhere to fall
    // back to, so the accents do not tint the whole canvas.
    for _ in 0..2 {
        let radius = rng.range(0.4, 0.7) * f64::from(width);
        points.push(Point {
            x: rng.range(0.0, 1.0) * f64::from(width),
            y: rng.range(0.0, 1.0) * f64::from(height),
            rgb: background,
            falloff: radius * radius,
        });
    }

    let mut pixels = vec![0u8; (width * height * 3) as usize];
    let (center_x, center_y) = (f64::from(width) / 2.0, f64::from(height) / 2.0);
    let max_radius = (center_x * center_x + center_y * center_y).sqrt();

    for y in 0..height {
        for x in 0..width {
            let (mut r, mut g, mut b, mut total) = (0.0, 0.0, 0.0, 0.0);

            for point in &points {
                let dx = f64::from(x) - point.x;
                let dy = f64::from(y) - point.y;
                // +1.0 keeps the weight finite at the point itself.
                let weight = 1.0 / (1.0 + (dx * dx + dy * dy) / point.falloff).powi(2);
                r += point.rgb.0 * weight;
                g += point.rgb.1 * weight;
                b += point.rgb.2 * weight;
                total += weight;
            }

            let dx = f64::from(x) - center_x;
            let dy = f64::from(y) - center_y;
            let shade = 1.0 - VIGNETTE * ((dx * dx + dy * dy).sqrt() / max_radius).powi(2);

            let index = ((y * width + x) * 3) as usize;
            pixels[index] = clamp((r / total) * shade);
            pixels[index + 1] = clamp((g / total) * shade);
            pixels[index + 2] = clamp((b / total) * shade);
        }
    }

    Ok(pixels)
}

fn clamp(value: f64) -> u8 {
    value.round().clamp(0.0, 255.0) as u8
}

/// Generate a wallpaper and write it as a PNG.
pub fn write_png(
    palette: &Palette,
    seed: &str,
    width: u32,
    height: u32,
    path: &Path,
) -> Result<()> {
    let pixels = render(palette, seed, width, height)?;

    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)
            .with_context(|| format!("creating {}", parent.display()))?;
    }

    let file = std::fs::File::create(path)
        .with_context(|| format!("creating {}", path.display()))?;
    let mut encoder = png::Encoder::new(std::io::BufWriter::new(file), width, height);
    encoder.set_color(png::ColorType::Rgb);
    encoder.set_depth(png::BitDepth::Eight);

    encoder
        .write_header()
        .context("writing PNG header")?
        .write_image_data(&pixels)
        .with_context(|| format!("writing {}", path.display()))?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn theme_palette(name: &str) -> Palette {
        let colors = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .unwrap()
            .join("theme/themes")
            .join(name)
            .join("colors.toml");
        Palette::load(&colors).unwrap()
    }

    #[test]
    fn output_has_the_right_shape() {
        let pixels = render(&theme_palette("gruvbox"), "gruvbox", 64, 32).unwrap();
        assert_eq!(pixels.len(), 64 * 32 * 3);
    }

    #[test]
    fn generation_is_deterministic() {
        let palette = theme_palette("gruvbox");
        let first = render(&palette, "gruvbox", 64, 32).unwrap();
        let second = render(&palette, "gruvbox", 64, 32).unwrap();
        assert_eq!(first, second, "these files are regenerated, not committed");
    }

    #[test]
    fn different_themes_give_different_wallpapers() {
        let a = render(&theme_palette("gruvbox"), "gruvbox", 64, 32).unwrap();
        let b = render(&theme_palette("nord"), "nord", 64, 32).unwrap();
        assert_ne!(a, b);
    }

    #[test]
    fn stays_close_to_the_theme_background() {
        // The guard is contrast: a wallpaper sits behind windows, and one that
        // wanders far from the theme's own background fights whatever is on
        // top of it. The bound is on the *mean* across the canvas, so local
        // accent blooms are allowed while the field as a whole stays in the
        // theme's family. 60 is roughly a quarter of the 8-bit range — enough
        // for visible colour, not enough to read as a different palette.
        let palette = theme_palette("gruvbox");
        let background = parse_hex(palette.get("background").unwrap()).unwrap();
        let pixels = render(&palette, "gruvbox", 128, 128).unwrap();

        let count = (pixels.len() / 3) as f64;
        let mean = |offset: usize| {
            pixels.iter().skip(offset).step_by(3).map(|v| f64::from(*v)).sum::<f64>() / count
        };

        for (channel, actual) in [background.0, background.1, background.2]
            .iter()
            .zip([mean(0), mean(1), mean(2)])
        {
            let drift = (actual - f64::from(*channel)).abs();
            assert!(drift < 60.0, "drifted {drift:.1} from the background");
        }
    }

    #[test]
    fn a_light_theme_stays_light() {
        let palette = theme_palette("catppuccin-latte");
        let pixels = render(&palette, "catppuccin-latte", 64, 64).unwrap();
        let mean = pixels.iter().map(|v| f64::from(*v)).sum::<f64>() / pixels.len() as f64;
        assert!(mean > 170.0, "light theme produced a dark wallpaper: {mean:.1}");
    }

    #[test]
    fn writes_a_readable_png() {
        let directory = std::env::temp_dir().join(format!("dotstyle-wp-{}", std::process::id()));
        let path = directory.join("out.png");
        write_png(&theme_palette("nord"), "nord", 64, 32, &path).unwrap();

        let decoder = png::Decoder::new(std::io::BufReader::new(
            std::fs::File::open(&path).unwrap(),
        ));
        let reader = decoder.read_info().unwrap();
        assert_eq!(reader.info().width, 64);
        assert_eq!(reader.info().height, 32);

        std::fs::remove_dir_all(&directory).ok();
    }
}
