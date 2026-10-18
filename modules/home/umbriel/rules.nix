{lib, ...}: let
  # Port of modules/home/niri/rules.nix. A rule's match keys are ANDed and a
  # list under one key is ORed, so each entry below is one match table and
  # gets its own window_rule. Later rules override earlier ones. Regexes are
  # ECMAScript, matched anywhere in the string, hence the ^...$ anchors.
  # There is no exclude, so negative lookahead stands in for niri's exclude
  # lines.
  #
  # Not ported, beyond what niri's file already lists:
  # - Thunar and Chrome opening maximized: Umbriel ignores a restored maximize
  #   unless general.honor_restored_maximize is set.
  rule = match: body: body // {inherit match;};

  # Hyprland's "0.9 0.8" active/inactive opacity pair, plus whatever else the
  # group's windows get (body). Unlike niri's is-active, is_focused may also
  # turn false while a Noctalia panel has keyboard focus.
  translucent = matches: body:
    lib.concatMap (m: [
      (rule m (body
        // {
          opacity = 0.9;
          blur = true;
        }))
      (rule (m // {is_focused = false;}) {opacity = 0.8;})
    ])
    matches;

  terminals = [{app_id = ''^(com\.mitchellh\.ghostty|org\.wezfurlong\.wezterm|Alacritty|kitty|kitty-dropterm|dropterminal|so\.pen\.herdr-gpui)$'';}];
  fileManagers = [{app_id = ''^([Tt]hunar|org\.gnome\.Nautilus|[Pp]cmanfm-qt)$'';}];
  settings = [
    {
      app_id = [
        ''^dev\.noctalia\.Noctalia$''
        ''^io\.missioncenter\.MissionCenter$''
        "^(gnome-disks|wihotspot(-gui)?)$"
        ''^org\.gnome\.seahorse\.Application$''
        ''^(file-roller|org\.gnome\.FileRoller)$''
        "^(nm-applet|nm-connection-editor|blueman-manager)$"
        ''\.blueman-manager-wrapped''
        ''^(pavucontrol|org\.pulseaudio\.pavucontrol|com\.saivert\.pwvucontrol)$''
        "^(nwg-look|qt5ct|qt6ct|[Yy]ad)$"
        "xdg-desktop-portal-gtk"
        ''^dev\.noctalia\.UmbrielSharePicker$''
      ];
    }
    {title = "^Fcitx Configuration$";}
    # msime-linux-desktop also opens the handwriting/keyboard/emoji/...
    # panels as their own windows; only the main one has the settings title.
    {
      app_id = "^msime-linux-desktop$";
      title = "^水杉输入法 · 设置$";
    }
  ];
  floating = {default_floating = true;};
  size = width: height: floating // {default_floating_size = {inherit width height;};};
in {
  programs.umbriel.settings = {
    window_rule = lib.concatLists [
      (translucent settings (size 0.8 0.8))

      [
        (rule {title = "^(Picture-in-Picture|Picture in picture)$";} (floating
          // {
            default_position = {
              x = 32;
              y = 32;
              anchor = "top_right";
            };
          }))

        # Bitwarden extension's "pop out" window: Chrome opens it as an app
        # window whose app-id carries the extension ID (and profile suffix).
        (rule {app_id = "^chrome-nngceckbapebfimnlniiiahkandclblb-";} (floating
          // {
            default_floating_size_px = {
              width = 420;
              height = 680;
            };
          }))

        # Thunar's dialogs (progress, properties, ...): every Thunar window
        # whose title isn't the main window's "<dir> - Thunar".
        (rule {
            app_id = "^[Tt]hunar$";
            title = "^(?!.*[Tt]hunar)";
          }
          floating)
      ]

      (translucent [{title = "^Authentication Required$";}] floating)

      [
        (rule {app_id = ''^(mpv|com\.github\.rafostar\.Clapper)$'';} floating)

        # Steam's friends list, settings and other secondary windows; the main
        # window's title is "Steam".
        (rule {
            app_id = "^[Ss]team$";
            title = "^(?![Ss]team$)";
          }
          floating)

        (rule {title = ["Add Folder to Workspace" "Open Files"];} (size 0.7 0.6))
        (rule {title = "wants to save";} floating)
      ]

      (translucent fileManagers {})
      (translucent terminals {})

      [
        # VRR comes from the output's vrr = "fullscreen" (umbrielOutputSettings
        # in hosts/<host>/variables.nix).
        (rule {app_id = ''^steam_app\d+$'';} {default_fullscreen = true;})

        (rule {app_id = ''^org\.gnome\.Loupe$'';} (size 0.8 0.8))

        # Floating windows sit over other windows, so blur what's actually
        # behind them, as Hyprland does, rather than the optimized pass's
        # wallpaper-only blur. Tiled windows never overlap and keep the cheap
        # one.
        (rule {is_floating = true;} {blur_optimized = false;})
      ]
    ];

    # Umbriel lacks ext-background-effect, so Noctalia's blur is a layer rule.
    # The bar keeps the optimized blur: its exclusive zone means only
    # wallpaper is ever behind it. Panels, notifications and OSDs open over
    # windows.
    layer_rule = let
      blur = {
        blur = true;
        blur_ignore_alpha = 0.5;
        blur_popups = true;
      };
    in [
      (blur // {match.namespace = "^noctalia-(bar-.+|dock|desktop-widget-.*)$";})
      (blur
        // {
          match.namespace = "^noctalia-(panel|attached-panel|notification|osd)$";
          blur_optimized = false;
        })
    ];
  };
}
