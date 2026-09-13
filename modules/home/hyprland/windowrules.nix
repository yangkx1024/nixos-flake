_: {
  wayland.windowManager.hyprland = {
    extraConfig = ''
      -- Noctalia layer rule
      hl.layer_rule({
        name = "noctalia",
        match = {
          namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$",
        },
        ignore_alpha = 0.5,
        blur = true,
        blur_popups = true,
      })

      -- Thunar (xfconf last-window-maximized) and Chrome (Preferences
      -- browser.window_placement.maximized) ask to be maximized on startup.
      -- Hyprland honours that as FSMODE_MAXIMIZED, which pins the window over
      -- the whole workspace and makes hl.dsp.focus({direction=...}) a no-op
      -- until it is toggled off. Upstream's stock hyprland.lua ships this same
      -- rule; our generated config replaces it, so re-add it here.
      hl.window_rule({
        name = "suppress-maximize-events",
        match = { class = ".*" },
        suppress_event = "maximize",
      })

      -- Float and center modal dialog boxes
      hl.window_rule({
        match = { modal = true },
        float = true,
        center = true,
      })

      hl.window_rule({
        name = "Thunar",
        match = { class = [[^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$]] },
        tag = "+file-manager",
      })

      hl.window_rule({
        name = "Terminals",
        match = { class = [[^(com.mitchellh.ghostty|org.wezfurlong.wezterm|Alacritty|kitty|kitty-dropterm|dropterminal)$]] },
        tag = "+terminal",
      })

      hl.window_rule({
        name = "Google-chrome",
        match = { class = [[^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$]] },
        tag = "+browser",
      })

      hl.window_rule({
        name = "steam-app",
        match = { class = [[^(steam_app\d+)$]] },
        tag = "+games",
      })

      hl.window_rule({
        name = "Steam",
        match = { class = [[^([Ss]team)$]] },
        tag = "+gamestore",
      })

      hl.window_rule({
        name = "Noctalia-Settings",
        match = { class = [[^(dev\.noctalia\.Noctalia)$]] },
        tag = "+settings",
      })

      hl.window_rule({
        name = "MissionCenter",
        match = { initial_class = [[^(io\.missioncenter\.MissionCenter)$]] },
        tag = "+settings",
      })

      hl.window_rule({
        name = "gnome-disks",
        match = { class = [[^(gnome-disks|wihotspot(-gui)?)$]] },
        tag = "+settings",
      })

      hl.window_rule({
        name = "seahorse",
        match = { class = [[^(org\.gnome\.seahorse\.Application)$]] },
        tag = "+settings",
      })

      hl.window_rule({
        name = "FileRoller",
        match = { class = [[^(file-roller|org.gnome.FileRoller)$]] },
        tag = "+settings",
      })

      hl.window_rule({
        name = "NetworkManger",
        match = { class = [[^(nm-applet|nm-connection-editor|blueman-manager)$]] },
        tag = "+settings",
      })

      hl.window_rule({
        name = "PlusAudio",
        match = { class = [[^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$]] },
        center = true,
        tag = "+settings",
        no_blur = false,
      })

      hl.window_rule({
        name = "nwg-look",
        match = { class = [[^(nwg-look|qt5ct|qt6ct|[Yy]ad)$]] },
        tag = "+settings",
      })

      hl.window_rule({
        name = "xdg-desktop-portal-gtk",
        match = { class = [[(xdg-desktop-portal-gtk)]] },
        tag = "+settings",
      })

      hl.window_rule({
        name = "blueman",
        match = { class = [[(.blueman-manager-wrapped)]] },
        tag = "+settings",
      })

      hl.window_rule({
        name = "Fcitx-Configuration",
        match = { title = [[^(Fcitx Configuration)$]] },
        tag = "+settings",
      })

      hl.window_rule({
        name = "Picture-in-Picture",
        match = { title = [[^(Picture-in-Picture)$]] },
        float = true,
        move = { "monitor_w*0.72", "monitor_h*0.07" },
        pin = false,
        keep_aspect_ratio = true,
      })

      hl.window_rule({
        name = "ThunarFileMgr",
        match = { class = [[([Tt]hunar)]], title = [[negative:(.*[Tt]hunar.*)]] },
        center = true,
        float = true,
      })

      hl.window_rule({
        name = "Authentication-Required",
        match = { title = [[^(Authentication Required)$]] },
        center = true,
        float = true,
        opacity = "0.8 0.7",
      })

      hl.window_rule({
        name = "IdleInhibit-fullscreen-3",
        match = { fullscreen = true },
        idle_inhibit = "fullscreen",
      })

      hl.window_rule({
        name = "Settings-Tag",
        match = { tag = "settings*" },
        float = true,
        opacity = "0.9 0.8",
        -- Window-rule sizes are muparser expressions: "80%" is silently
        -- ignored, so use monitor_w/monitor_h (logical px) to stay scale-proof.
        size = { "monitor_w*0.8", "monitor_h*0.8" },
        no_blur = false,
      })

      hl.window_rule({
        name = "mpv-or-clapper",
        match = { class = [[^(mpv|com.github.rafostar.Clapper)$]] },
        float = true,
      })

      hl.window_rule({
        name = "Steam-float",
        match = { class = [[^([Ss]team)$]], title = [[negative:^([Ss]team)$]] },
        float = true,
      })

      hl.window_rule({
        name = "Add-Folder",
        match = { initial_title = [[(Add Folder to Workspace)]] },
        float = true,
        size = { "monitor_w*0.7", "monitor_h*0.6" },
      })

      hl.window_rule({
        name = "Open-File",
        match = { initial_title = [[(Open Files)]] },
        float = true,
        size = { "monitor_w*0.7", "monitor_h*0.6" },
      })

      hl.window_rule({
        name = "Wants-to-Save",
        match = { initial_title = [[(wants to save)]] },
        float = true,
      })

      hl.window_rule({
        name = "Browsers",
        match = { tag = "browser*" },
        opacity = "1.0 1.0",
      })

      hl.window_rule({
        name = "File-Managers",
        match = { tag = "file-manager*" },
        opacity = "0.8 0.7",
      })

      hl.window_rule({
        name = "Terminals-opacity",
        match = { tag = "terminal*" },
        opacity = "0.8 0.7",
        no_blur = false,
      })

      hl.window_rule({
        name = "windowrule-79",
        match = { tag = "games*" },
        no_blur = true,
      })

      hl.window_rule({
        name = "windowrule-80",
        match = { tag = "games*" },
        fullscreen = true,
      })

      hl.window_rule({
        name = "Loupe",
        match = { class = [[^(org\.gnome\.Loupe)$]] },
        center = true,
        float = true,
        opacity = "1.0 1.0",
        size = { "monitor_w*0.8", "monitor_h*0.8" },
      })
    '';
  };
}
