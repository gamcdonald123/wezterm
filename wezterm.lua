-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where we apply your config choices

local is_linux = wezterm.target_triple:find("linux") ~= nil

-- Same Meslo on both: the Nerd Font build is named differently on the Mac
-- and on Fedora (where it's the powerlevel10k "MesloLGS NF" copy).
config.font = wezterm.font(is_linux and "MesloLGS NF" or "MesloLGS Nerd Font Mono")
-- Linux points render larger than macOS points at the same scale.
config.font_size = is_linux and 10 or 19
-- Under Sway the tiling WM owns the window size; letting WezTerm resize itself
-- on font changes leaves it drawing a small window inside the tile.
config.adjust_window_size_when_changing_font_size = false

config.enable_tab_bar = true

config.window_background_opacity = 1
config.macos_window_background_blur = 10

config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true

-- config.background = {
--   {
--     source = { File ="/Users/gamcdonald/Downloads/877224.jpg" },
--     width = "100%",
--     height = "100%",
--     horizontal_align = "Center",
--     vertical_align = "Middle",
--     repeat_x = "NoRepeat",
--     repeat_y = "NoRepeat",
--     hsb = {
--       brightness = 0.5
--     },
--     attachment = "Fixed",
--   },
-- }

config.enable_kitty_graphics = true
config.enable_tab_bar = false

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
    {key="LeftArrow", mods="CMD", action=wezterm.action{ActivatePaneDirection="Prev"}},
    
    {key="p", mods = "CTRL | SHIFT", action=wezterm.action.DisableDefaultAssignment},
    {key="P", mods = "CTRL | SHIFT", action=wezterm.action.DisableDefaultAssignment},
    {key="N", mods = "CTRL | SHIFT", action=wezterm.action.DisableDefaultAssignment},
    {key="n", mods = "CTRL | SHIFT", action=wezterm.action.DisableDefaultAssignment},

  }

-- Colour schemes: a shortlist to flick through (neon / Tokyo / Blade Runner / Matrix).
--   Cmd+Shift+]  next scheme      Cmd+Shift+[  previous scheme
--   Cmd+Shift+S  pick by name (current one marked)
-- The choice applies to every window and is remembered in a per-machine state
-- file (not this repo), so the Mac and Linux can differ.
local schemes = {
  "Neon (terminal.sexy)", "Neon", "Neon Night (Gogh)", "Cobalt Neon",
  "Tokyo Night", "Tokyo Night Storm", "Tokyo Night Moon",
  "synthwave", "synthwave-everything", "Outrun Dark (base16)", "Laserwave (Gogh)",
  "Cyberdyne", "cyberpunk", "Scarlet Protocol", "Vice Dark (base16)",
  "Synth Midnight Terminal Dark (base16)",
  "Matrix (terminal.sexy)", "matrix", "darkmatrix", "Blue Matrix",
}
local default_scheme = "Neon (terminal.sexy)"
local scheme_file = (os.getenv("XDG_STATE_HOME") or (wezterm.home_dir .. "/.local/state"))
  .. "/wezterm/color_scheme"

local function read_scheme()
  local f = io.open(scheme_file, "r")
  if not f then return default_scheme end
  local name = f:read("*l"); f:close()
  return (name and name ~= "") and name or default_scheme
end

local function set_scheme(name)
  os.execute("mkdir -p '" .. scheme_file:match("(.*)/") .. "'")
  local f = io.open(scheme_file, "w")
  if f then f:write(name, "\n"); f:close() end
  wezterm.reload_configuration()
end

local function step_scheme(delta)
  return wezterm.action_callback(function(window)
    local current, idx = read_scheme(), 0
    for i, n in ipairs(schemes) do if n == current then idx = i end end
    local nxt = (idx - 1 + delta) % #schemes + 1
    set_scheme(schemes[nxt])
    -- shown by mako
    window:toast_notification("WezTerm", string.format("%s  (%d/%d)", schemes[nxt], nxt, #schemes), nil, 1500)
  end)
end

local function pick_scheme()
  return wezterm.action_callback(function(window, pane)
    local current, choices = read_scheme(), {}
    for _, n in ipairs(schemes) do
      table.insert(choices, { id = n, label = (n == current and "● " or "  ") .. n })
    end
    window:perform_action(act.InputSelector({
      title = "Colour scheme",
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(_, _, id)
        if id then set_scheme(id) end
      end),
    }), pane)
  end)
end

-- Small per-scheme colour tweaks, layered over the built-in schemes.
local scheme_tweaks = {
  -- stock text is dark olive (#3e5715): hard to read, so make it Matrix green
  darkmatrix = { foreground = "#22e051" },
}
config.color_schemes = {}
local builtin = wezterm.color.get_builtin_schemes()
for name, tweak in pairs(scheme_tweaks) do
  local s = builtin[name]
  for k, v in pairs(tweak) do s[k] = v end
  config.color_schemes[name] = s
end

config.color_scheme = read_scheme()

-- Very slightly dim what doesn't have focus: split panes inside a window...
config.inactive_pane_hsb = { saturation = 0.95, brightness = 0.85 }
-- ...and whole WezTerm windows when another Sway window has focus (inactive_pane_hsb
-- only covers splits within one window).
wezterm.on("window-focus-changed", function(window)
  local overrides = window:get_config_overrides() or {}
  if window:is_focused() then
    overrides.foreground_text_hsb = nil
  else
    overrides.foreground_text_hsb = { saturation = 0.95, brightness = 0.8 }
  end
  window:set_config_overrides(overrides)
end)

-- Shifted keys can arrive as either form depending on layout, so bind both.
for _, k in ipairs({ "]", "}" }) do
  table.insert(config.keys, { key = k, mods = "CMD|SHIFT", action = step_scheme(1) })
end
for _, k in ipairs({ "[", "{" }) do
  table.insert(config.keys, { key = k, mods = "CMD|SHIFT", action = step_scheme(-1) })
end
for _, k in ipairs({ "s", "S" }) do
  table.insert(config.keys, { key = k, mods = "CMD|SHIFT", action = pick_scheme() })
end

-- and finally, return the configuration to wezterm
return config

