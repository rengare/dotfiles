//! Enumerating the monospace families installed on this machine.

/// Monospace families known to fontconfig, deduplicated and sorted.
///
/// Returns an empty list when fontconfig is unavailable — callers fall back to
/// the family already in settings, so the font tab degrades to read-only
/// rather than breaking.
pub fn monospace_families() -> Vec<String> {
    let Ok(output) = std::process::Command::new("fc-list")
        .args([":mono", "family"])
        .output()
    else {
        return Vec::new();
    };

    let mut families: Vec<String> = String::from_utf8_lossy(&output.stdout)
        .lines()
        // fc-list prints a comma-separated list of aliases per font; any of
        // them is a name the config files can use.
        .flat_map(|line| line.split(','))
        .map(str::trim)
        .filter(|family| !family.is_empty())
        .map(str::to_string)
        .collect();

    families.sort();
    families.dedup();
    families
}
