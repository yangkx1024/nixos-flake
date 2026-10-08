{...}: {
  programs.wezterm = {
    enable = true;
    # The module prepends `local wezterm = require 'wezterm'`
    extraConfig = ''
      local config = wezterm.config_builder()

      config.color_scheme = "Noctalia"
      -- 12pt here == 16pt on macOS: at 2x WezTerm uses 192 DPI on Wayland, 144 on macOS
      config.font_size = 12
      config.font = wezterm.font('Maple Mono NF CN')

      config.window_padding = {
        left = 8,
        right = 8,
        top = 8,
        bottom = 8,
      }

      config.hide_tab_bar_if_only_one_tab = true

      config.default_cursor_style = "BlinkingBar"
      config.cursor_thickness = "1pt"
      config.cursor_blink_rate = 500
      config.max_fps = 144
      config.animation_fps = 30
      config.enable_scroll_bar = true
      config.mouse_bindings = {
        -- Fixed 3 lines per wheel event instead of the event's own delta
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

      -- ALT|SHIFT so plain ALT keys still reach the shell (zsh push-line, transpose-words, ...)
      config.keys = {
        -- Tab management
        { key = "t", mods = "ALT|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
        { key = "w", mods = "ALT|SHIFT", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
        { key = "n", mods = "ALT|SHIFT", action = wezterm.action.ActivateTabRelative(1) },
        { key = "p", mods = "ALT|SHIFT", action = wezterm.action.ActivateTabRelative(-1) },

        -- Pane management
        { key = "v", mods = "ALT|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
        { key = "h", mods = "ALT|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
        { key = "q", mods = "ALT|SHIFT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },

        -- Pane navigation (ALT|SHIFT + Arrows)
        { key = "LeftArrow", mods = "ALT|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
        { key = "RightArrow", mods = "ALT|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
        { key = "UpArrow", mods = "ALT|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
        { key = "DownArrow", mods = "ALT|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },
      }
      return config
    '';
  };
}
