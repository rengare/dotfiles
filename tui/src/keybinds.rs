//! Reading the sway config's keybindings.
//!
//! Sway exposes no IPC query for bindings, so the config file is the only
//! source. That means doing the two things sway's own parser does before a
//! binding means anything: following `include` directives, and substituting
//! `set $var` variables — an unsubstituted `$mod+$shift+q` is useless in a
//! cheatsheet.

use std::collections::HashMap;
use std::path::{Path, PathBuf};

use anyhow::{Context, Result};

/// One binding, ready to display.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Binding {
    /// `Mod4+Shift+q`, or `swipe:4:right` for a gesture.
    pub keys: String,
    /// The command sway runs.
    pub command: String,
    /// The `# --- Section ---` heading this binding sits under, if any.
    pub section: String,
    /// The nearest preceding plain `# comment` line. The sway config uses
    /// `# --- X ---` for broad areas and a plain `# Launch apps` immediately
    /// above each group, so this is the more useful of the two labels.
    pub group: String,
    /// The trailing `# comment` on the binding's own line, if any.
    pub note: String,
}

impl Binding {
    /// The most specific label available for this binding.
    pub fn label(&self) -> &str {
        if !self.note.is_empty() {
            &self.note
        } else if !self.group.is_empty() {
            &self.group
        } else {
            &self.section
        }
    }

    /// A single line for a picker: keys, command, and whatever context exists.
    pub fn display(&self) -> String {
        let context = self.label().to_string();
        if context.is_empty() {
            format!("{:<28} {}", self.keys, self.command)
        } else {
            format!("{:<28} {:<44} {}", self.keys, self.command, context)
        }
    }
}

/// Parse a sway config and everything it includes.
pub fn parse_config(path: &Path) -> Result<Vec<Binding>> {
    let mut variables = HashMap::new();
    let mut bindings = Vec::new();
    parse_into(path, &mut variables, &mut bindings, 0)?;
    Ok(bindings)
}

/// Recursion depth cap: a config that includes itself would otherwise loop
/// forever, and sway itself tolerates such a file by simply warning.
const MAX_INCLUDE_DEPTH: usize = 8;

fn parse_into(
    path: &Path,
    variables: &mut HashMap<String, String>,
    bindings: &mut Vec<Binding>,
    depth: usize,
) -> Result<()> {
    if depth > MAX_INCLUDE_DEPTH {
        return Ok(());
    }

    let source = std::fs::read_to_string(path)
        .with_context(|| format!("reading {}", path.display()))?;
    let directory = path.parent().unwrap_or(Path::new("."));
    let mut section = String::new();
    let mut group = String::new();

    for line in source.lines() {
        let trimmed = line.trim();

        if let Some(heading) = section_heading(trimmed) {
            section = heading;
            // A new area supersedes whatever group was in force.
            group.clear();
            continue;
        }
        if let Some(comment) = trimmed.strip_prefix('#') {
            let comment = comment.trim();
            // A blank `#` is a spacer, not a label.
            if !comment.is_empty() {
                group = comment.to_string();
            }
            continue;
        }
        if trimmed.is_empty() {
            continue;
        }

        if let Some(rest) = trimmed.strip_prefix("set ") {
            if let Some((name, value)) = rest.trim().split_once(char::is_whitespace) {
                // Variables can be defined in terms of earlier ones.
                let value = substitute(value.trim(), variables);
                variables.insert(name.trim().to_string(), value);
            }
            continue;
        }

        if let Some(rest) = trimmed.strip_prefix("include ") {
            let target = substitute(rest.trim(), variables);
            for included in expand_include(directory, &target) {
                // A missing include is sway's problem to warn about, not a
                // reason to fail building a cheatsheet.
                let _ = parse_into(&included, variables, bindings, depth + 1);
            }
            continue;
        }

        if let Some(binding) = parse_binding(trimmed, variables, &section, &group) {
            bindings.push(binding);
        }
    }

    Ok(())
}

/// `# --- Keybindings (matching niri) ---` -> `Keybindings (matching niri)`.
///
/// The config already groups itself this way, so the cheatsheet inherits that
/// structure instead of inventing one.
fn section_heading(line: &str) -> Option<String> {
    let rest = line.strip_prefix('#')?.trim();
    let heading = rest.trim_matches(|c: char| c == '-' || c.is_whitespace());
    if rest.starts_with("---") && !heading.is_empty() {
        Some(heading.to_string())
    } else {
        None
    }
}

fn parse_binding(
    line: &str,
    variables: &HashMap<String, String>,
    section: &str,
    group: &str,
) -> Option<Binding> {
    let (verb, rest) = line.split_once(char::is_whitespace)?;
    if !matches!(verb, "bindsym" | "bindcode" | "bindgesture") {
        return None;
    }

    // Skip any `--to-code`, `--release`, `--no-repeat` style flags.
    let mut rest = rest.trim_start();
    while rest.starts_with("--") {
        let (_, tail) = rest.split_once(char::is_whitespace)?;
        rest = tail.trim_start();
    }

    let (keys, command) = rest.split_once(char::is_whitespace)?;

    // A trailing comment is only a comment when it follows whitespace; a '#'
    // inside the command (a colour literal, a shell comment in an exec) is not.
    let (command, note) = match command.find(" #") {
        Some(index) => (&command[..index], command[index + 2..].trim().to_string()),
        None => (command, String::new()),
    };

    Some(Binding {
        keys: substitute(keys, variables),
        command: substitute(command.trim(), variables),
        section: section.to_string(),
        group: group.to_string(),
        note,
    })
}

/// Replace `$name` with its value, longest name first.
///
/// Longest-first matters: with `$mod` and `$mod1` both defined, replacing
/// `$mod` first would turn `$mod1` into `Mod4` followed by a stray `1`.
fn substitute(text: &str, variables: &HashMap<String, String>) -> String {
    if !text.contains('$') || variables.is_empty() {
        return text.to_string();
    }

    let mut names: Vec<&String> = variables.keys().collect();
    names.sort_by_key(|name| std::cmp::Reverse(name.len()));

    let mut out = text.to_string();
    for name in names {
        if out.contains(name.as_str()) {
            out = out.replace(name.as_str(), &variables[name]);
        }
    }
    out
}

/// Resolve an include target, which sway allows to be relative, absolute,
/// `~`-prefixed, or a glob.
fn expand_include(directory: &Path, target: &str) -> Vec<PathBuf> {
    let expanded = match target.strip_prefix("~/") {
        Some(rest) => std::env::var_os("HOME")
            .map(PathBuf::from)
            .unwrap_or_default()
            .join(rest),
        None => PathBuf::from(target),
    };

    let absolute = if expanded.is_absolute() {
        expanded
    } else {
        directory.join(expanded)
    };

    if !target.contains('*') {
        return vec![absolute];
    }

    // Only a trailing `dir/*` glob is supported, which is the form sway configs
    // actually use for drop-in directories.
    let Some(parent) = absolute.parent() else {
        return Vec::new();
    };
    let Ok(entries) = std::fs::read_dir(parent) else {
        return Vec::new();
    };
    let mut matches: Vec<PathBuf> = entries
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .filter(|path| path.is_file())
        .collect();
    matches.sort();
    matches
}

#[cfg(test)]
mod tests {
    use super::*;

    fn parse_text(text: &str) -> Vec<Binding> {
        let directory = std::env::temp_dir().join(format!(
            "dotstyle-keybinds-{}-{:?}",
            std::process::id(),
            std::thread::current().id()
        ));
        std::fs::create_dir_all(&directory).unwrap();
        let path = directory.join("config");
        std::fs::write(&path, text).unwrap();
        let bindings = parse_config(&path).unwrap();
        std::fs::remove_dir_all(&directory).ok();
        bindings
    }

    #[test]
    fn substitutes_variables() {
        let bindings = parse_text(
            "set $mod Mod4\nset $shift Shift\nbindsym $mod+$shift+q kill\n",
        );
        assert_eq!(bindings.len(), 1);
        assert_eq!(bindings[0].keys, "Mod4+Shift+q");
        assert_eq!(bindings[0].command, "kill");
    }

    #[test]
    fn substitutes_inside_commands_too() {
        let bindings = parse_text("set $term foot\nbindsym Mod4+Return exec $term\n");
        assert_eq!(bindings[0].command, "exec foot");
    }

    #[test]
    fn variables_can_reference_earlier_variables() {
        let bindings = parse_text(
            "set $mod Mod4\nset $combo $mod+Shift\nbindsym $combo+q kill\n",
        );
        assert_eq!(bindings[0].keys, "Mod4+Shift+q");
    }

    #[test]
    fn longer_variable_names_win() {
        // Replacing $mod first would leave "Mod4" + a stray "1".
        let bindings = parse_text("set $mod Mod4\nset $mod1 Mod1\nbindsym $mod1+q kill\n");
        assert_eq!(bindings[0].keys, "Mod1+q");
    }

    #[test]
    fn parses_gestures_and_keycodes() {
        let bindings = parse_text(
            "bindgesture swipe:4:right workspace prev\nbindcode 133 exec foot\n",
        );
        assert_eq!(bindings[0].keys, "swipe:4:right");
        assert_eq!(bindings[0].command, "workspace prev");
        assert_eq!(bindings[1].keys, "133");
    }

    #[test]
    fn skips_binding_flags() {
        let bindings = parse_text("bindsym --to-code --no-repeat Mod4+j focus down\n");
        assert_eq!(bindings[0].keys, "Mod4+j");
        assert_eq!(bindings[0].command, "focus down");
    }

    #[test]
    fn a_hash_inside_a_command_is_not_a_comment() {
        // A colour literal in an exec is the realistic case.
        let bindings = parse_text("bindsym Mod4+c exec notify-send '#ff0000'\n");
        assert_eq!(bindings[0].command, "exec notify-send '#ff0000'");
        assert_eq!(bindings[0].note, "");
    }

    #[test]
    fn a_trailing_comment_becomes_the_note() {
        let bindings = parse_text("bindsym Mod4+q kill # close the window\n");
        assert_eq!(bindings[0].command, "kill");
        assert_eq!(bindings[0].note, "close the window");
    }

    #[test]
    fn groups_by_section_heading() {
        let bindings = parse_text(
            "# --- Launch apps ---\n\
             bindsym Mod4+Return exec foot\n\
             \n\
             # --- Focus (vim) ---\n\
             bindsym Mod4+h focus left\n",
        );
        assert_eq!(bindings[0].section, "Launch apps");
        assert_eq!(bindings[1].section, "Focus (vim)");
    }

    #[test]
    fn plain_comments_become_the_group_label() {
        // This is how the real config is written: one broad `---` area with
        // plain comments labelling each group inside it.
        let bindings = parse_text(
            "# --- Keybindings ---\n\
             # Launch apps\n\
             bindsym Mod4+Return exec foot\n\
             bindsym Mod4+t exec foot\n\
             # Focus (vim)\n\
             bindsym Mod4+h focus left\n",
        );
        assert_eq!(bindings[0].group, "Launch apps");
        assert_eq!(bindings[1].group, "Launch apps", "carries to the next binding");
        assert_eq!(bindings[2].group, "Focus (vim)");
        assert_eq!(bindings[0].section, "Keybindings", "the area is still recorded");
    }

    #[test]
    fn the_most_specific_label_wins() {
        let bindings = parse_text(
            "# --- Area ---\n# Group\nbindsym Mod4+q kill # close it\n",
        );
        assert_eq!(bindings[0].label(), "close it", "the note beats the group");

        let bindings = parse_text("# --- Area ---\n# Group\nbindsym Mod4+q kill\n");
        assert_eq!(bindings[0].label(), "Group", "the group beats the area");

        let bindings = parse_text("# --- Area ---\nbindsym Mod4+q kill\n");
        assert_eq!(bindings[0].label(), "Area");
    }

    #[test]
    fn a_new_area_clears_the_group() {
        let bindings = parse_text(
            "# --- One ---\n# Group\nbindsym Mod4+a nop\n\
             # --- Two ---\nbindsym Mod4+b nop\n",
        );
        assert_eq!(bindings[1].group, "", "a stale group would mislabel this");
        assert_eq!(bindings[1].label(), "Two");
    }

    #[test]
    fn ignores_everything_that_is_not_a_binding() {
        let bindings = parse_text(
            "output eDP-1 { mode 1920x1080 }\n\
             exec_always autotiling\n\
             bindsym Mod4+q kill\n\
             gaps inner 16\n",
        );
        assert_eq!(bindings.len(), 1);
    }

    #[test]
    fn follows_includes_and_shares_variables() {
        let directory = std::env::temp_dir().join(format!(
            "dotstyle-keybinds-include-{}",
            std::process::id()
        ));
        std::fs::create_dir_all(&directory).unwrap();
        std::fs::write(directory.join("extra"), "bindsym $mod+x exec foo\n").unwrap();
        std::fs::write(
            directory.join("config"),
            "set $mod Mod4\ninclude extra\nbindsym $mod+q kill\n",
        )
        .unwrap();

        let bindings = parse_config(&directory.join("config")).unwrap();
        assert_eq!(bindings.len(), 2);
        assert_eq!(bindings[0].keys, "Mod4+x", "the include's binding, substituted");
        assert_eq!(bindings[1].keys, "Mod4+q");

        std::fs::remove_dir_all(&directory).ok();
    }

    #[test]
    fn a_missing_include_is_not_fatal() {
        let bindings = parse_text("include /nonexistent/file\nbindsym Mod4+q kill\n");
        assert_eq!(bindings.len(), 1);
    }
}
