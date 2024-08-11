local wezterm = require("wezterm")
local act = wezterm.action
local config = {
	default_prog = { "fish" },
	font = wezterm.font("JetBrains Mono Nerd Font"),
	font_size = 16.0,
	color_scheme = "GruvboxDark",
	-- window_background_opacity = 0.9,
	hide_tab_bar_if_only_one_tab = true,
	mouse_bindings = {
		{
			event = { Down = { streak = 1, button = "Right" } },
			mods = "NONE",
			action = wezterm.action_callback(function(window, pane)
				local has_selection = window:get_selection_text_for_pane(pane) ~= ""
				if has_selection then
					window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
					window:perform_action(act.ClearSelection, pane)
				else
					window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
				end
			end),
		},
	},

	keys = {
		{
			key = "c",
			mods = "CTRL",
			action = wezterm.action_callback(function(window, pane)
				selection_text = window:get_selection_text_for_pane(pane)
				is_selection_active = string.len(selection_text) ~= 0
				if is_selection_active then
					window:perform_action(wezterm.action.CopyTo("ClipboardAndPrimarySelection"), pane)
				else
					window:perform_action(wezterm.action.SendKey({ key = "c", mods = "CTRL" }), pane)
				end
			end),
		},
	},
}

return config
