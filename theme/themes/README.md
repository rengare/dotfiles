# Themes

Palettes ported from [Omarchy](https://omarchy.org) (`omarchy/themes/*`), MIT-licensed —
see `LICENSE-omarchy`. Each theme is a flat `colors.toml` of semantic color tokens,
optional `backgrounds/`, an optional `neovim.lua` colorscheme spec, and an optional
`light.mode` marker.

Add your own by dropping a directory here with a `colors.toml`. Tokens you leave out
are derived by the resolver in `tui/src/palette.rs`.
