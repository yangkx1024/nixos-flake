{
  host,
  pkgs,
  inputs,
  username,
  ...
}: let
  vars = import ../../../hosts/${host}/variables.nix;
  extraMonitorSettings = vars.extraMonitorSettings or "";
in {
  home.packages = with pkgs; [
    grim
    slurp
    swappy
    ydotool
    hyprpolkitagent
    hyprshot
    hyprshutdown
    hyprpicker
    hyprland-qtutils # needed for banners and ANR messages
  ];
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];
  # Place Files Inside Home Directory
  home.file = {
    ".face.icon".source = ./face.jpg;
    ".config/face.jpg".source = ./face.jpg;
  };
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    systemd = {
      enable = true;
      enableXdgAutostart = true;
      variables = ["--all"];
    };
    xwayland = {
      enable = true;
    };
    settings = {
      config = {
        input = {
          kb_layout = "us";
          kb_options = "grp:alt_caps_toggle, caps:super";
          numlock_by_default = true;
          repeat_delay = 300;
          follow_mouse = 1;
          float_switch_override_focus = 0;
          sensitivity = 0;
          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            scroll_factor = 0.8;
          };
        };

        gestures = {
          workspace_swipe_distance = 500;
          workspace_swipe_invert = true;
          workspace_swipe_min_speed_to_force = 30;
          workspace_swipe_cancel_ratio = 0.5;
          workspace_swipe_create_new = true;
          workspace_swipe_forever = true;
        };

        scrolling = {
          column_width = 0.95;
          fullscreen_on_one_column = true;
          direction = "right";
          follow_focus = true;
        };

        general = {
          layout = "scrolling";
          gaps_in = 6;
          gaps_out = 8;
          border_size = 2;
          resize_on_border = true;
        };

        misc = {
          layers_hog_keyboard_focus = true;
          initial_workspace_tracking = 0;
          mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          enable_swallow = false;
          vrr = 2; # Variable Refresh Rate  Might need to set to 0 for NVIDIA/AQ_DRM_DEVICES
          # Screen flashing to black momentarily or going black when app is fullscreen
          # Try setting vrr to 0

          #  Application not responding (ANR) settings
          enable_anr_dialog = true;
          anr_missed_pings = 15;
        };

        dwindle = {
          preserve_split = true;
          smart_resizing = true;
          use_active_for_splits = true;
          smart_split = false;
          default_split_ratio = 1.0;
          split_bias = 0;
          precise_mouse_move = false;
          special_scale_factor = 0.8;
        };

        decoration = {
          rounding = 10;
          blur = {
            enabled = true;
            size = 5;
            passes = 3;
            ignore_opacity = true;
            new_optimizations = true;
          };
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };
        };

        ecosystem = {
          no_donation_nag = true;
          no_update_news = false;
        };

        cursor = {
          sync_gsettings_theme = true;
          no_hardware_cursors = 2; # change to 1 if want to disable
          enable_hyprcursor = true;
          warp_on_change_workspace = 2;
          persistent_warps = true;
        };

        render = {
          # Disabling as no longer supported
          #explicit_sync = 1; # Change to 1 to disable
          #explicit_sync_kms = 1;
          direct_scanout = 0;
        };

        master = {
          new_status = "slave";
          new_on_top = false;
          new_on_active = "none";
          orientation = "left";
          mfact = 0.55;
          slave_count_for_center_master = 2;
          center_master_fallback = "left";
          smart_resizing = true;
          drop_at_cursor = true;
          always_keep_position = false;
        };

        # Ensure Xwayland windows render at integer scale; compositor scales them
        xwayland = {
          force_zero_scaling = true;
        };
      };

      gesture = [
        {
          fingers = 3;
          direction = "horizontal";
          action = "workspace";
        }
      ];
    };

    extraConfig = ''
      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
      hl.monitor({ output = "Virtual-1", mode = "1920x1080@60", position = "auto", scale = 1 })
      ${extraMonitorSettings}

      -- Apply noctalia-generated colors. The file is hyprlang ($vars + sections),
      -- and Lua's require() can't load .conf, so parse it and feed hl.config().
      do
        local path = "/home/${username}/.config/hypr/noctalia/noctalia-colors.conf"
        local f = io.open(path, "r")
        if f then
          local vars, root, stack = {}, {}, {}
          local cur = root
          for raw in f:lines() do
            local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmed == "" or trimmed:sub(1, 1) == "#" then
              -- skip blanks and comments
            elseif trimmed:sub(1, 1) == "$" then
              local k, v = trimmed:match("^%$([%w_]+)%s*=%s*(.+)$")
              if k then vars[k] = v end
            elseif trimmed:match("{$") then
              local name = trimmed:match("^([%w_]+)")
              if name then
                cur[name] = cur[name] or {}
                stack[#stack + 1] = cur
                cur = cur[name]
              end
            elseif trimmed == "}" then
              cur = table.remove(stack) or root
            else
              local k, v = trimmed:match("^([%w_%.]+)%s*=%s*(.+)$")
              if k and v then
                v = v:gsub("%$([%w_]+)", function(n) return vars[n] or "" end)
                local target, parts = cur, {}
                for p in k:gmatch("[^%.]+") do parts[#parts + 1] = p end
                for i = 1, #parts - 1 do
                  target[parts[i]] = target[parts[i]] or {}
                  target = target[parts[i]]
                end
                target[parts[#parts]] = v
              end
            end
          end
          f:close()
          hl.config(root)
        end
      end
    '';
  };
}
