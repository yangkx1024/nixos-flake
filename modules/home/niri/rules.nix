{lib, ...}: let
  # Port of modules/home/hyprland/windowrules.nix. niri has no tags, so each
  # Hyprland tag is a list of KDL matchers here; every matcher becomes its own
  # `match` line, and a window matching any of them gets the rule. Later rules
  # override earlier ones. app-id and title are regexes matched anywhere in the
  # string, hence the explicit ^...$ anchors. title is read when the window
  # opens, which is what Hyprland's initial_title did.
  #
  # Not ported:
  # - Zen's Bitwarden popout. Zen only sets its title after the window opens,
  #   and niri's open-* properties are decided before that. Hyprland's Lua
  #   hook on title changes has no niri equivalent short of a script on
  #   `niri msg event-stream`.
  # - idle_inhibit for fullscreen windows: niri has no such rule. Players and
  #   browsers inhibit idle themselves; Noctalia's caffeine toggle covers the
  #   rest.
  # - Modal dialogs: niri already floats any window with a parent and opens
  #   new floating windows centered, so no rule is needed.
  # - Noctalia's layer rule: Noctalia requests its own blur, shaped to its
  #   panels, through ext-background-effect.
  # - Browsers at opacity 1.0: that's niri's default.
  # Matchers with a backslash need KDL raw strings (r#"..."#): \. is not a
  # valid escape in a plain KDL string.
  matches = suffix: matchers: lib.concatMapStrings (m: "    match ${m}${suffix}\n") matchers;

  # Hyprland's "active inactive" opacity pair, plus whatever else the group's
  # windows get (body). Matchers within one `match` line are ANDed, so the
  # inactive rule repeats each matcher with is-active=false. is-active rather
  # than is-focused, so that opening a Noctalia panel doesn't dim the window
  # behind it. Blur is xray (it shows the wallpaper), niri's default and
  # cheap; the border would otherwise be drawn as a solid rectangle showing
  # through the window.
  translucent = matchers: active: inactive: body: ''
    window-rule {
    ${matches "" matchers}${lib.concatMapStrings (l: lib.optionalString (l != "") "    ${l}\n") (lib.splitString "\n" body)}    opacity ${active}
        draw-border-with-background false
        background-effect {
            blur true
        }
    }
    window-rule {
    ${matches " is-active=false" matchers}    opacity ${inactive}
    }
  '';

  terminals = [''app-id=r#"^(com\.mitchellh\.ghostty|org\.wezfurlong\.wezterm|Alacritty|kitty|kitty-dropterm|dropterminal)$"#''];
  fileManagers = [''app-id=r#"^([Tt]hunar|org\.gnome\.Nautilus|[Pp]cmanfm-qt)$"#''];
  settings = [
    ''app-id=r#"^dev\.noctalia\.Noctalia$"#''
    ''app-id=r#"^io\.missioncenter\.MissionCenter$"#''
    ''app-id=r#"^(gnome-disks|wihotspot(-gui)?)$"#''
    ''app-id=r#"^org\.gnome\.seahorse\.Application$"#''
    ''app-id=r#"^(file-roller|org\.gnome\.FileRoller)$"#''
    ''app-id=r#"^(nm-applet|nm-connection-editor|blueman-manager)$"#''
    ''app-id=r#"\.blueman-manager-wrapped"#''
    ''app-id=r#"^(pavucontrol|org\.pulseaudio\.pavucontrol|com\.saivert\.pwvucontrol)$"#''
    ''app-id=r#"^(nwg-look|qt5ct|qt6ct|[Yy]ad)$"#''
    ''app-id="xdg-desktop-portal-gtk"''
    ''title="^Fcitx Configuration$"''
    # msime-linux-desktop also opens the handwriting/keyboard/emoji/...
    # panels as their own windows; only the main one has the settings title.
    ''app-id="^msime-linux-desktop$" title="^水杉输入法 · 设置$"''
  ];
in {
  wayland.windowManager.niri.extraConfig = lib.concatStrings [
    # Every window: rounded corners.
    ''
      window-rule {
          geometry-corner-radius 10
          clip-to-geometry true
      }
    ''

    # Thunar (xfconf last-window-maximized) and Chrome (Preferences
    # browser.window_placement.maximized) ask to open maximized; keep them in
    # a normal column instead, like Hyprland's suppress_event = "maximize".
    ''
      window-rule {
          open-maximized-to-edges false
      }
    ''

    (translucent settings "0.9" "0.8" ''
      open-floating true
      default-column-width { proportion 0.8; }
      default-window-height { proportion 0.8; }
    '')

    ''
      window-rule {
          match title="^Picture-in-Picture$"
          open-floating true
          default-floating-position x=32 y=32 relative-to="top-right"
      }
    ''

    # Bitwarden extension's "pop out" window: Chrome opens it as an app
    # window whose app-id carries the extension ID (and profile suffix).
    ''
      window-rule {
          match app-id="^chrome-nngceckbapebfimnlniiiahkandclblb-"
          open-floating true
          default-column-width { fixed 420; }
          default-window-height { fixed 680; }
      }
    ''

    # Thunar's dialogs (progress, properties, ...): every Thunar window whose
    # title isn't the main window's "<dir> - Thunar".
    ''
      window-rule {
          match app-id="^[Tt]hunar$"
          exclude title="[Tt]hunar"
          open-floating true
      }
    ''

    (translucent [''title="^Authentication Required$"''] "0.8" "0.7" ''
      open-floating true
    '')

    ''
      window-rule {
          match app-id=r#"^(mpv|com\.github\.rafostar\.Clapper)$"#
          open-floating true
      }
    ''

    # Steam's friends list, settings and other secondary windows; the main
    # window's title is "Steam".
    ''
      window-rule {
          match app-id="^[Ss]team$"
          exclude title="^[Ss]team$"
          open-floating true
      }
    ''

    ''
      window-rule {
          match title="Add Folder to Workspace"
          match title="Open Files"
          open-floating true
          default-column-width { proportion 0.7; }
          default-window-height { proportion 0.6; }
      }

      window-rule {
          match title="wants to save"
          open-floating true
      }
    ''

    (translucent fileManagers "0.8" "0.7" "")
    (translucent terminals "0.8" "0.7" "")

    # Hyprland's vrr = 2 (fullscreen only) becomes on-demand VRR on the
    # output (niriOutputSettings in hosts/<host>/variables.nix), turned on
    # by these windows.
    ''
      window-rule {
          match app-id=r#"^steam_app\d+$"#
          open-fullscreen true
          variable-refresh-rate true
      }

      window-rule {
          match app-id=r#"^org\.gnome\.Loupe$"#
          open-floating true
          default-column-width { proportion 0.8; }
          default-window-height { proportion 0.8; }
      }
    ''
  ];
}
