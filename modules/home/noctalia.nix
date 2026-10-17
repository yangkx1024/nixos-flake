{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    # Template hooks run with the session PATH. The ghostty hook reloads a
    # directly launched Ghostty over D-Bus with gdbus; its pgrep -x ghostty
    # fallback never matches the nixpkgs-wrapped .ghostty-wrapped process, so
    # without gdbus open terminals keep the old palette after a mode switch.
    glib
    # needed for noctalia-shell screen-recorder plugin
    gpu-screen-recorder
    # The usbeehive plugin pipes `usbeehive --watch --json` through jq.
    jq
  ];
  programs.noctalia = {
    enable = true;
    # noctalia reads the icon theme (and writes color-scheme) through the
    # org.gnome.desktop.interface GSettings schema. Without
    # gsettings-desktop-schemas on XDG_DATA_DIRS the lookup fails ("No schemas
    # installed") and the bar/tray fall back to hicolor's generic glyphs.
    # Upstream fixed this in its own flake's wrapper (noctalia-dev/noctalia#4061);
    # nixpkgs' package (as of 5.2.1) never adopted it. Drop this once
    # pkgs/by-name/no/noctalia/package.nix prefixes the schemas itself.
    # A symlinkJoin keeps the cache.nixos.org binary.
    package = pkgs.symlinkJoin {
      name = "noctalia-${pkgs.noctalia.version}";
      paths = [pkgs.noctalia];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/noctalia \
          --prefix XDG_DATA_DIRS : ${pkgs.glib.getSchemaDataDirPath pkgs.gsettings-desktop-schemas}
      '';
      inherit (pkgs.noctalia) meta version;
    };
    settings = {
      shell = {
        font_family = "MiSans";
        avatar_path = "${config.xdg.configHome}/face.jpg";
        telemetry_enabled = true;
        clipboard_auto_paste = "off";
        launch_apps_as_systemd_services = true;
        polkit_agent = true;
        # Push wallpaper/palette/mode/font to noctalia-greeter on change; no
        # prompt thanks to passwordless-sync-users in modules/core/greetd.nix.
        greeter_sync.auto_sync = true;
        shadow.direction = "down_right";
        panel = {
          transparency_mode = "glass";
          # launcher_placement = "centered";
          # session_placement = "centered";
          control_center_placement = "attached";
          open_near_click_control_center = true;
        };
        window_switcher = {
          stype = "compact";
          show_all_outputs = true;
        };
      };

      theme = {
        mode = "auto";
        source = "builtin";
        builtin = "Ayu";

        templates = {
          builtin_ids = ["gtk3" "gtk4" "kcolorscheme" "qt" "wezterm" "hyprland" "niri" "btop" "ghostty"];
          community_ids = ["bat" "fcitx5" "fzf" "herdr" "hyprtoolkit" "lazygit" "neovim" "zed"];
        };
      };

      wallpaper = {
        enabled = true;
        directory = "~/Pictures/Wallpapers";
        fill_mode = "crop";
        transition = ["fade" "disc" "stripes" "wipe" "honeycomb"];
        transition_duration = 1500;
        edge_smoothness = 0.05;
        transition_on_startup = true;
        default.path = "~/Pictures/Wallpapers/default.jpg";
        automation = {
          enabled = false;
          interval_seconds = 300;
          order = "random";
        };
      };

      lockscreen = {
        blur_intensity = 0.8;
        tint_intensity = 0.3;
      };

      location = {
        auto_locate = true;
        address = "Singapore";
      };

      weather = {
        enabled = true;
        unit = "celsius";
        effects = true;
      };

      notification.position = "top_right";
      osd.position = "top_right";

      idle.behavior = {
        lock = {
          enabled = true;
          timeout = 600;
          command = "noctalia:session lock";
        };
        "screen-off" = {
          enabled = true;
          timeout = 600;
          command = "noctalia:dpms-off";
          resume_command = "noctalia:dpms-on";
        };
        suspend = {
          enabled = true;
          timeout = 1800;
          action = "suspend";
        };
      };

      dock = {
        enabled = false;
        pinned = ["thunar" "google-chrome" "steam" "dev.zed.Zed"];
      };

      bar.main = {
        position = "top";
        background_opacity = 0.8;
        contact_shadow = true;
        radius = 0;
        margin_ends = 0;
        margin_edge = 0;
        padding = 8;
        capsule = true;
        capsule_opacity = 1;
        start = ["workspaces" "active_window" "media"];
        center = ["clock"];
        end = ["audio_visualizer" "temp" "ram" "sysmon" "usb" "tray" "volume" "notifications" "control-center"];
      };

      plugins = {
        # All from the built-in official and community sources.
        enabled = ["noctalia/translator" "noctalia/screen_recorder" "yangkx/usbeehive"];
      };

      # Keys may contain '/', so per-plugin settings live in a top-level table.
      plugin_settings."yangkx/usbeehive".notify_hotplug = false;

      widget = {
        clock = {
          format = "{:%Y年%m月%d日 %A %H:%M}";
          vertical_format = "{:%H %M - %m %d}";
          tooltip_format = "{:%Y年%m月%d日 %A %H:%M:%S}";
        };
        audio_visualizer = {
          width = 100;
          show_when_idle = false;
        };
        media.hide_when_no_media = true;
        cpu.visualization = "none";
        temp.visualization = "none";
        ram.visualization = "none";
        sysmon = {
          stat = "disk_used_pct";
          visualization = "none";
        };
        # USB devices / USB-C charging wattage (plugins.enabled above); needs
        # usbeehive (modules/core/usbeehive.nix) and jq on PATH.
        usb.type = "yangkx/usbeehive:usb";
      };

      control_center.shortcuts = [
        {type = "bluetooth";}
        {type = "dark_mode";}
        {type = "notification";}
        {type = "power_profile";}
        {type = "caffeine";}
        {type = "noctalia/screen_recorder:toggle";}
      ];
    };
  };
}
