{
  config,
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  noctaliaPkg = inputs.noctalia.packages.${system}.default;
in {
  # Install the Noctalia package
  home.packages = [
    noctaliaPkg
  ];
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    settings = {
      shell = {
        ui_scale = 1.2;
        font_family = "MiSans";
        avatar_path = "${config.xdg.configHome}/face.jpg";
        telemetry_enabled = true;
        clipboard_auto_paste = "off";
        launch_apps_as_systemd_services = true;
        shadow.direction = "down_right";
        panel = {
          transparency_mode = "glass";
          launcher_placement = "centered";
          session_placement = "centered";
          control_center_placement = "attached";
          open_near_click_control_center = true;
        };
      };

      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Ayu";

        templates = {
          builtin_ids = ["gtk3" "gtk4" "kcolorscheme" "qt" "wezterm" "hyprland" "btop" "ghostty"];
          community_ids = ["hyprtoolkit" "zed"];
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
        background_opacity = 0.75;
        contact_shadow = true;
        radius = 0;
        margin_ends = 0;
        margin_edge = 0;
        content_padding = 8;
        scale = 1.2;
        capsule = true;
        capsule_opacity = 1;
        start = ["launcher" "workspaces" "active_window" "media"];
        center = ["clock"];
        end = ["audio_visualizer" "temp" "cpu" "ram" "disk" "tray" "volume" "notifications" "control-center"];
      };

      widget = {
        clock = {
          format = "{:%Y年%m月%d日 %A %H:%M}";
          vertical_format = "{:%H %M - %m %d}";
          tooltip_format = "{:%Y年%m月%d日 %A %H:%M:%S}";
        };
        launcher.glyph = "rocket";
        audio_visualizer = {
          width = 100;
          show_when_idle = false;
        };
        media.hide_when_no_media = true;
        cpu.display = "text";
        temp.display = "text";
        ram.display = "text";
        network_rx.display = "text";
        network_tx.display = "text";
        disk = {
          type = "sysmon";
          stat = "disk_pct";
          display = "text";
        };
      };

      control_center.shortcuts = [
        {type = "wifi";}
        {type = "bluetooth";}
        {type = "wallpaper";}
        {type = "dark_mode";}
        {type = "notification";}
        {type = "power_profile";}
        {type = "caffeine";}
        {type = "screen_recorder";}
      ];
    };
  };
}
