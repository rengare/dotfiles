//! Hex color parsing and the linear-RGB mixer.
//!
//! `mix` is a port of the awk block in `omarchy-theme-set-templates`, kept
//! bit-identical (round-half-up on each channel) so palettes derived here match
//! the upstream themes they came from.

/// Parse `#rrggbb` (or a bare `rrggbb`) into 8-bit channels.
pub fn parse_hex(value: &str) -> Option<(u8, u8, u8)> {
    let hex = value.strip_prefix('#').unwrap_or(value);
    if hex.len() != 6 || !hex.chars().all(|c| c.is_ascii_hexdigit()) {
        return None;
    }
    let byte = |i: usize| u8::from_str_radix(&hex[i..i + 2], 16).ok();
    Some((byte(0)?, byte(2)?, byte(4)?))
}

pub fn is_hex(value: &str) -> bool {
    value.starts_with('#') && parse_hex(value).is_some()
}

/// `#1a1b26` -> `26,27,38`, for consumers that want decimal triplets (dunst, gtk).
pub fn to_rgb_triplet(value: &str) -> Option<String> {
    let (r, g, b) = parse_hex(value)?;
    Some(format!("{r},{g},{b}"))
}

/// Amounts accept `0.3`, `30`, or `30%` — all meaning the same thing, matching
/// upstream's lenient parsing. Out-of-range values clamp rather than error.
pub fn parse_amount(raw: &str) -> f64 {
    let raw = raw.trim();
    let amount = match raw.strip_suffix('%') {
        Some(rest) => rest.trim().parse::<f64>().unwrap_or(0.0) / 100.0,
        None => {
            let n = raw.parse::<f64>().unwrap_or(0.0);
            if n > 1.0 {
                n / 100.0
            } else {
                n
            }
        }
    };
    amount.clamp(0.0, 1.0)
}

/// Linearly interpolate between two hex colors.
pub fn mix(start: &str, end: &str, amount: f64) -> Option<String> {
    let (sr, sg, sb) = parse_hex(start)?;
    let (er, eg, eb) = parse_hex(end)?;
    let blend = |s: u8, e: u8| (s as f64 * (1.0 - amount) + e as f64 * amount + 0.5) as u8;
    Some(format!(
        "#{:02x}{:02x}{:02x}",
        blend(sr, er),
        blend(sg, eg),
        blend(sb, eb)
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_and_rejects() {
        assert_eq!(parse_hex("#1a1b26"), Some((0x1a, 0x1b, 0x26)));
        assert_eq!(parse_hex("1a1b26"), Some((0x1a, 0x1b, 0x26)));
        assert_eq!(parse_hex("#xyz"), None);
        assert_eq!(parse_hex("#1a1b2"), None);
        assert!(!is_hex("rgba(1a1b26ff)"));
    }

    #[test]
    fn amount_forms_agree() {
        assert_eq!(parse_amount("30%"), 0.3);
        assert_eq!(parse_amount("0.3"), 0.3);
        assert_eq!(parse_amount("30"), 0.3);
        assert_eq!(parse_amount("-5"), 0.0);
        assert_eq!(parse_amount("500"), 1.0);
    }

    #[test]
    fn mixes_like_upstream_awk() {
        // Values cross-checked against omarchy-theme-set-templates' mix_color.
        assert_eq!(mix("#1a1b26", "#000000", 0.25).as_deref(), Some("#14141d"));
        assert_eq!(mix("#1a1b26", "#000000", 0.5).as_deref(), Some("#0d0e13"));
        assert_eq!(mix("#f7768e", "#ffffff", 0.2).as_deref(), Some("#f991a5"));
        assert_eq!(mix("#000000", "#ffffff", 0.5).as_deref(), Some("#808080"));
        assert_eq!(mix("#ffffff", "#000000", 0.0).as_deref(), Some("#ffffff"));
    }

    #[test]
    fn rgb_triplet() {
        assert_eq!(to_rgb_triplet("#1a1b26").as_deref(), Some("26,27,38"));
    }
}
