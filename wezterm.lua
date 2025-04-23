-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where we apply your config choices

config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 19

config.enable_tab_bar = true

config.window_background_opacity = 1
config.macos_window_background_blur = 10

config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true

config.keys = {
  -- clear scrollback and viewport
  {
    key = 'k',
    mods = 'CMD',
    action = act.ClearScrollback 'ScrollbackAndViewport',
  },
  -- Cycle to the next pane
    {key="RightArrow", mods="CMD", action=wezterm.action{ActivatePaneDirection="Next"}},
  -- Cycle to the previous pane
    {key="LeftArrow", mods="CMD", action=wezterm.action{ActivatePaneDirection="Prev"}}
  }

-- my coolnight colorscheme:
config.color_scheme = 'Neon (terminal.sexy)'

-- and finally, return the configuration to wezterm
return config

