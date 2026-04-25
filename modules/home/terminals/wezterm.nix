{pkgs, ...}: {
  programs.wezterm = {
    enable = true;
    package = pkgs.wezterm;
  };
  home.file."./.config/wezterm/wezterm.lua".text = ''
    -- Config from Drew @justaguylinux small mods

     local wezterm = require("wezterm")

     local config = wezterm.config_builder()

     config.enable_wayland = true

     -- General appearance and visuals
     config.colors = {
       tab_bar = {
         background = "#00141d", -- col_gray1, your main DWM bar background

         active_tab = {
           bg_color = "#80bfff", -- col_gray2 (selected tab in bright blue)
           fg_color = "#00141d", -- contrast text on active tab
         },

         inactive_tab = {
           bg_color = "#1a1a1a", -- col_gray4 (dark background for inactive tabs)
           fg_color = "#FFFFFF", -- col_gray3 (white text on inactive tabs)
         },

         new_tab = {
           bg_color = "#1a1a1a", -- same as inactive
           fg_color = "#4fc3f7", -- col_barbie (for the "+" button)
         },
       },
     }

     config.window_background_opacity = 1
     config.color_scheme = "Noctalia"
     config.font_size = 14
     config.font = wezterm.font_with_fallback {
       'Maple Mono NF CN',
       'JetBrainsMono NF',
     }

     config.window_padding = {
       left = 8,
       right = 8,
       top = 8,
       bottom = 8,
     }

     config.use_fancy_tab_bar = true
     config.hide_tab_bar_if_only_one_tab = true

     config.default_cursor_style = "BlinkingBar"
     config.cursor_thickness = "1pt"
     config.cursor_blink_rate = 500
     config.term = "xterm-256color"
     config.max_fps = 144
     config.animation_fps = 30
     config.enable_scroll_bar = true
     config.mouse_bindings = {
       -- Slower scroll up/down (3 lines instead of Page Up/Down)
       {
         event = { Down = { streak = 1, button = { WheelUp = 1 } } },
         mods = 'NONE',
         action = wezterm.action.ScrollByLine(-3),
         alt_screen = false,
       },
       {
         event = { Down = { streak = 1, button = { WheelDown = 1 } } },
         mods = 'NONE',
         action = wezterm.action.ScrollByLine(3),
         alt_screen = false,
       },
     }

     -- Keybindings using ALT for tabs & splits
     config.keys = {
       -- Tab management
       { key = "t", mods = "ALT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
       { key = "w", mods = "ALT", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
       { key = "n", mods = "ALT", action = wezterm.action.ActivateTabRelative(1) },
       { key = "p", mods = "ALT", action = wezterm.action.ActivateTabRelative(-1) },

       -- Pane management
       { key = "v", mods = "ALT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
       { key = "h", mods = "ALT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
       { key = "q", mods = "ALT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },

       -- Pane navigation (move between panes with ALT + Arrows)
       { key = "LeftArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Left") },
       { key = "RightArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Right") },
       { key = "UpArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Up") },
       { key = "DownArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Down") },
     }
    return config
  '';
}
