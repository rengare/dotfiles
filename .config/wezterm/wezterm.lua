local wezterm = require("wezterm")

return {
	default_prog = { "fish" },
	font = wezterm.font("JetBrains Mono Nerd Font"),
	font_size = 16.0,
	color_scheme = "GruvboxDark",
	-- window_background_opacity = 0.9,
	hide_tab_bar_if_only_one_tab = true,
}
