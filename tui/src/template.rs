//! The `{{ token }}` expander.
//!
//! Deliberately tiny — a full template language would be a liability here,
//! since every directive has to be reimplementable by anyone hand-editing a
//! `.tpl`. Four forms exist:
//!
//! | form                          | yields                    |
//! |-------------------------------|---------------------------|
//! | `{{ background }}`            | `#1a1b26`                 |
//! | `{{ background_strip }}`      | `1a1b26`                  |
//! | `{{ background_rgb }}`        | `26,27,38`                |
//! | `{{ mix background red 30% }}`| the blended hex           |
//!
//! `mix` also has `mix_strip` and `mix_rgb` variants. Unlike upstream, an
//! unresolved directive is an error rather than a placeholder silently
//! surviving into a config file.

use std::collections::HashMap;

use anyhow::{bail, Result};
use regex::Regex;

use crate::color::{is_hex, mix, parse_amount, to_rgb_triplet};

/// The variables one render pass expands against: palette tokens plus the
/// non-color settings (font family, gaps, …).
#[derive(Debug, Default, Clone)]
pub struct Context {
    values: HashMap<String, String>,
}

impl Context {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn insert(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.values.insert(key.into(), value.into());
    }

    pub fn get(&self, key: &str) -> Option<&str> {
        self.values.get(key).map(String::as_str)
    }
}

fn directive_pattern() -> &'static Regex {
    static PATTERN: std::sync::OnceLock<Regex> = std::sync::OnceLock::new();
    PATTERN.get_or_init(|| Regex::new(r"\{\{\s*([^{}]+?)\s*\}\}").expect("directive regex"))
}

/// Expand every directive in `source`. `name` only appears in error messages.
pub fn render(name: &str, source: &str, context: &Context) -> Result<String> {
    let mut unresolved: Vec<String> = Vec::new();

    let output = directive_pattern().replace_all(source, |captures: &regex::Captures| {
        let body = &captures[1];
        match expand(body, context) {
            Some(value) => value,
            None => {
                unresolved.push(body.to_string());
                captures[0].to_string()
            }
        }
    });

    if !unresolved.is_empty() {
        unresolved.dedup();
        bail!(
            "{name}: unresolved template directive(s): {}",
            unresolved.join(", ")
        );
    }

    Ok(output.into_owned())
}

fn expand(body: &str, context: &Context) -> Option<String> {
    let mut parts = body.split_whitespace();
    let head = parts.next()?;

    if matches!(head, "mix" | "mix_strip" | "mix_rgb") {
        let start = context.get(parts.next()?)?;
        let end = context.get(parts.next()?)?;
        let amount = parse_amount(parts.next()?);
        if parts.next().is_some() {
            return None;
        }
        let mixed = mix(start, end, amount)?;
        return match head {
            "mix" => Some(mixed),
            "mix_strip" => Some(strip(&mixed)),
            _ => to_rgb_triplet(&mixed),
        };
    }

    // Plain token, possibly with a `_strip` / `_rgb` suffix. A token whose own
    // name ends in those letters still wins, so the lookup is tried first.
    if parts.next().is_some() {
        return None;
    }
    if let Some(value) = context.get(head) {
        return Some(value.to_string());
    }
    if let Some(base) = head.strip_suffix("_strip") {
        return context.get(base).map(strip);
    }
    if let Some(base) = head.strip_suffix("_rgb") {
        return context.get(base).filter(|v| is_hex(v)).and_then(to_rgb_triplet);
    }
    None
}

fn strip(value: &str) -> String {
    value.strip_prefix('#').unwrap_or(value).to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn context() -> Context {
        let mut context = Context::new();
        context.insert("background", "#1a1b26");
        context.insert("foreground", "#a9b1d6");
        context.insert("font_family", "JetBrainsMono Nerd Font");
        context
    }

    #[test]
    fn expands_the_four_forms() {
        let context = context();
        let out = render(
            "t",
            "a={{ background }} b={{ background_strip }} c={{ background_rgb }} \
             d={{ mix background foreground 50% }} e={{ font_family }}",
            &context,
        )
        .unwrap();
        assert_eq!(
            out,
            "a=#1a1b26 b=1a1b26 c=26,27,38 d=#62667e e=JetBrainsMono Nerd Font"
        );
    }

    #[test]
    fn mix_variants() {
        let context = context();
        assert_eq!(
            render("t", "{{ mix_strip background foreground 50% }}", &context).unwrap(),
            "62667e"
        );
        assert_eq!(
            render("t", "{{ mix_rgb background foreground 50% }}", &context).unwrap(),
            "98,102,126"
        );
    }

    #[test]
    fn whitespace_is_flexible() {
        let context = context();
        assert_eq!(render("t", "{{background}}", &context).unwrap(), "#1a1b26");
        assert_eq!(
            render("t", "{{   mix   background foreground   0.5  }}", &context).unwrap(),
            "#62667e"
        );
    }

    #[test]
    fn unknown_token_is_an_error_not_a_leak() {
        let context = context();
        let error = render("sway.conf", "{{ nope }} {{ alsonope }}", &context).unwrap_err();
        let message = error.to_string();
        assert!(message.contains("sway.conf"), "{message}");
        assert!(message.contains("nope"), "{message}");
        assert!(message.contains("alsonope"), "{message}");
    }

    #[test]
    fn non_hex_values_have_no_rgb_form() {
        let context = context();
        assert!(render("t", "{{ font_family_rgb }}", &context).is_err());
    }

    #[test]
    fn leaves_unrelated_braces_alone() {
        let context = context();
        assert_eq!(
            render("t", "bar { position top }", &context).unwrap(),
            "bar { position top }"
        );
    }
}
