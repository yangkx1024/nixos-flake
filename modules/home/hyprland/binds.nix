{host, ...}: let
  vars = import ../../../hosts/${host}/variables.nix;
  inherit
    (vars)
    browser
    terminal
    ;
in {
  wayland.windowManager.hyprland.extraConfig = ''
    do
      local mainMod = "SUPER"
      local ipc = "noctalia msg"

      -- ============= NOCTALIA =============
      hl.bind(mainMod .. " + SPACE",        hl.dsp.exec_cmd(ipc .. " panel-toggle launcher"))
      hl.bind(mainMod .. " + M",            hl.dsp.exec_cmd(ipc .. " panel-toggle control-center notifications"))
      hl.bind(mainMod .. " + SHIFT + V",    hl.dsp.exec_cmd(ipc .. " panel-toggle clipboard"))
      hl.bind(mainMod .. " + ALT + P",      hl.dsp.exec_cmd(ipc .. " settings-toggle"))
      hl.bind(mainMod .. " + comma",        hl.dsp.exec_cmd(ipc .. " settings-toggle"))
      hl.bind(mainMod .. " + CTRL + L",     hl.dsp.exec_cmd(ipc .. " session lock"))
      hl.bind(mainMod .. " + SHIFT + W",    hl.dsp.exec_cmd(ipc .. " panel-toggle wallpaper"))
      hl.bind(mainMod .. " + SHIFT + X",    hl.dsp.exec_cmd(ipc .. " panel-toggle session"))
      hl.bind(mainMod .. " + N",            hl.dsp.exec_cmd(ipc .. " panel-toggle control-center"))
      hl.bind(mainMod .. " + SHIFT + R",    hl.dsp.exec_cmd("bash -c 'pkill -x noctalia; sleep 0.3; noctalia'"))

      -- ============= MACOS-STYLE EDIT KEYS =============
      -- SUPER+C/V/X/A/Z/S are re-emitted as whatever the focused app already
      -- listens for, so they work everywhere without per-app config.
      -- Terminals are the exception: CTRL+C is SIGINT, CTRL+V is readline's
      -- quoted-insert and CTRL+A is beginning-of-line, so those use the
      -- CTRL+SHIFT bindings terminals expose instead. Cut, undo and save have
      -- no terminal equivalent and are dropped there rather than firing CTRL+X
      -- (readline prefix), CTRL+Z (SIGTSTP, suspending a TUI) or CTRL+S (XOFF,
      -- which freezes the terminal until CTRL+Q).
      local terminalClasses = {
        ["com.mitchellh.ghostty"] = true,
        ["org.wezfurlong.wezterm"] = true,
        ["Alacritty"] = true,
        ["kitty"] = true,
        ["kitty-dropterm"] = true,
        ["dropterminal"] = true,
      }

      local terminalMods = {
        C = "CTRL SHIFT",
        V = "CTRL SHIFT",
        A = "CTRL SHIFT",
        S = false,
        X = false,
        Z = false,
      }

      local function editKey(key)
        return function()
          local win = hl.get_active_window()
          local mods = "CTRL"
          if win and terminalClasses[win.class] then
            mods = terminalMods[key]
            if not mods then
              return
            end
          end
          hl.dispatch(hl.dsp.send_shortcut({ mods = mods, key = key, window = "activewindow" }))
        end
      end

      hl.bind(mainMod .. " + C",            editKey("C"))
      hl.bind(mainMod .. " + V",            editKey("V"))
      hl.bind(mainMod .. " + X",            editKey("X"))
      hl.bind(mainMod .. " + A",            editKey("A"))
      hl.bind(mainMod .. " + Z",            editKey("Z"))
      hl.bind(mainMod .. " + S",            editKey("S"))

      -- ============= TERMINALS =============
      hl.bind(mainMod .. " + Return",       hl.dsp.exec_cmd("${terminal}"))

      -- ============= APPLICATION LAUNCHERS =============
      hl.bind(mainMod .. " + B",            hl.dsp.exec_cmd("${browser}"))

      -- ============= SCREENSHOTS =============
      hl.bind(mainMod .. " + G",            hl.dsp.exec_cmd("screenshootin"))
      hl.bind(mainMod .. " + CTRL + G",     hl.dsp.exec_cmd("hyprshot -m output -o $HOME/Pictures/Screenshots"))
      hl.bind(mainMod .. " + SHIFT + G",    hl.dsp.exec_cmd("hyprshot -m window -o $HOME/Pictures/Screenshots"))
      hl.bind(mainMod .. " + ALT + G",      hl.dsp.exec_cmd("hyprshot -m region -o $HOME/Pictures/Screenshots"))
      hl.bind(mainMod .. " + ALT + C",      hl.dsp.exec_cmd("hyprpicker -a"))
      hl.bind(mainMod .. " + T",            hl.dsp.exec_cmd("thunar"))
      hl.bind(mainMod .. " + ALT + M",      hl.dsp.exec_cmd("pavucontrol"))

      -- ============= WINDOW MANAGEMENT =============
      hl.bind(mainMod .. " + Q",            hl.dsp.window.close())
      hl.bind(mainMod .. " + P",            hl.dsp.window.pseudo())
      hl.bind(mainMod .. " + F",            hl.dsp.window.fullscreen())
      hl.bind(mainMod .. " + SHIFT + F",    hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + ALT + F",      hl.dsp.exec_cmd("hyprland-float-all"))

      -- ============= LAYOUTS =============
      hl.bind(mainMod .. " + ALT + L",      hl.dsp.exec_cmd("hyprland-change-layout toggle"))
      hl.bind(mainMod .. " + ALT + 1",      hl.dsp.exec_cmd("hyprland-change-layout dwindle"))
      hl.bind(mainMod .. " + ALT + 2",      hl.dsp.exec_cmd("hyprland-change-layout master"))
      hl.bind(mainMod .. " + ALT + 3",      hl.dsp.exec_cmd("hyprland-change-layout scrolling"))
      hl.bind(mainMod .. " + ALT + 4",      hl.dsp.exec_cmd("hyprland-change-layout monocle"))
      hl.bind(mainMod .. " + SHIFT + C",    hl.dsp.exit())

      -- ============= WINDOW MOVEMENT (ARROW KEYS) =============
      hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
      hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
      hl.bind(mainMod .. " + SHIFT + up",   hl.dsp.window.move({ direction = "up" }))
      hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

      -- ============= WINDOW MOVEMENT (VI STYLE) =============
      hl.bind(mainMod .. " + SHIFT + h",    hl.dsp.window.move({ direction = "left" }))
      hl.bind(mainMod .. " + SHIFT + l",    hl.dsp.window.move({ direction = "right" }))
      hl.bind(mainMod .. " + SHIFT + k",    hl.dsp.window.move({ direction = "up" }))
      hl.bind(mainMod .. " + SHIFT + j",    hl.dsp.window.move({ direction = "down" }))

      -- ============= WINDOW SWAPPING (ARROW KEYS) =============
      hl.bind(mainMod .. " + ALT + left",   hl.dsp.window.swap({ direction = "left" }))
      hl.bind(mainMod .. " + ALT + right",  hl.dsp.window.swap({ direction = "right" }))
      hl.bind(mainMod .. " + ALT + up",     hl.dsp.window.swap({ direction = "up" }))
      hl.bind(mainMod .. " + ALT + down",   hl.dsp.window.swap({ direction = "down" }))

      -- ============= WINDOW SWAPPING (VI KEYCODES) =============
      hl.bind(mainMod .. " + ALT + code:43", hl.dsp.window.swap({ direction = "left" }))
      hl.bind(mainMod .. " + ALT + code:46", hl.dsp.window.swap({ direction = "right" }))
      hl.bind(mainMod .. " + ALT + code:45", hl.dsp.window.swap({ direction = "up" }))
      hl.bind(mainMod .. " + ALT + code:44", hl.dsp.window.swap({ direction = "down" }))

      -- ============= FOCUS MOVEMENT (ARROW KEYS) =============
      hl.bind(mainMod .. " + left",         hl.dsp.focus({ direction = "left" }))
      hl.bind(mainMod .. " + right",        hl.dsp.focus({ direction = "right" }))
      hl.bind(mainMod .. " + up",           hl.dsp.focus({ direction = "up" }))
      hl.bind(mainMod .. " + down",         hl.dsp.focus({ direction = "down" }))

      -- ============= FOCUS MOVEMENT (VI STYLE) =============
      hl.bind(mainMod .. " + h",            hl.dsp.focus({ direction = "left" }))
      hl.bind(mainMod .. " + l",            hl.dsp.focus({ direction = "right" }))
      hl.bind(mainMod .. " + k",            hl.dsp.focus({ direction = "up" }))
      hl.bind(mainMod .. " + j",            hl.dsp.focus({ direction = "down" }))

      -- ============= WORKSPACE SWITCHING (1-9) =============
      for i = 1, 9 do
        hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
        hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
      end

      -- ============= SPECIAL WORKSPACE =============
      hl.bind(mainMod .. " + SHIFT + 0",    hl.dsp.window.move({ workspace = "special" }))
      hl.bind(mainMod .. " + 0",            hl.dsp.workspace.toggle_special(""))

      -- ============= WORKSPACE NAVIGATION =============
      hl.bind(mainMod .. " + CONTROL + right", hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mainMod .. " + CONTROL + left",  hl.dsp.focus({ workspace = "e-1" }))
      hl.bind(mainMod .. " + mouse_down",   hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mainMod .. " + mouse_up",     hl.dsp.focus({ workspace = "e-1" }))

      -- ============= WINDOW CYCLING =============
      hl.bind("ALT + Tab", function()
        hl.dispatch(hl.dsp.window.cycle_next())
        hl.dispatch(hl.dsp.window.bring_to_top())
      end)

      -- ============= MEDIA & HARDWARE CONTROLS =============
      hl.bind("XF86AudioRaiseVolume",       hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
      hl.bind("XF86AudioLowerVolume",       hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
      hl.bind("XF86AudioMute",              hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
      hl.bind("XF86AudioPlay",              hl.dsp.exec_cmd("playerctl play-pause"))
      hl.bind("XF86AudioPause",             hl.dsp.exec_cmd("playerctl play-pause"))
      hl.bind("XF86AudioNext",              hl.dsp.exec_cmd("playerctl next"))
      hl.bind("XF86AudioPrev",              hl.dsp.exec_cmd("playerctl previous"))
      hl.bind("XF86MonBrightnessDown",      hl.dsp.exec_cmd("brightnessctl set 5%-"))
      hl.bind("XF86MonBrightnessUp",        hl.dsp.exec_cmd("brightnessctl set +5%"))

      -- ============= MOUSE BINDS =============
      hl.bind(mainMod .. " + mouse:272",    hl.dsp.window.drag())
      hl.bind(mainMod .. " + mouse:273",    hl.dsp.window.resize())
    end
  '';
}
