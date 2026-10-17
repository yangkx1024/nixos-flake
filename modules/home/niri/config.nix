{
  vars,
  config,
  lib,
  ...
}: let
  cursor = config.home.pointerCursor;
in {
  # niri runs as niri.service, so it and everything it spawns take their
  # environment from the systemd user manager, as do the apps noctalia
  # launches as systemd units (launch_apps_as_systemd_services). environment.d
  # is therefore the one place niri needs these; niri --session sets
  # XDG_CURRENT_DESKTOP=niri itself.
  systemd.user.sessionVariables = import ../session-env.nix {inherit vars cursor;};

  # Home Manager's module rather than niri-flake's, which would bring back a
  # separately pinned nixpkgs. Config is plain KDL in extraConfig, merged from
  # this file, binds.nix and rules.nix, and checked with `niri validate` at
  # build time. The file is a store symlink, so noctalia's niri template hook
  # (assets/templates/niri/apply.sh) finds the include line already there and
  # never tries to append to it.
  wayland.windowManager.niri = {
    enable = true;
    # programs.niri (modules/core/niri.nix) installs the units and the portal;
    # the package stays set because checkConfig needs it.
    systemd.enable = false;
    portalPackage = null;
    # xwaylandSatellitePackage stays at its default: niri spawns it on demand
    # when an X11 client connects and exports DISPLAY.

    extraConfig = lib.mkMerge [
      ''
        input {
            keyboard {
                xkb {
                    layout "us"
                    options "grp:alt_caps_toggle,caps:super"
                }
                repeat-delay 300
                numlock
            }
            touchpad {
                tap
                dwt
                natural-scroll
                scroll-factor 0.5
                click-method "clickfinger"
            }
            // Like Hyprland's follow_mouse = 1, but crossing a partly visible
            // column doesn't scroll the view to it.
            focus-follows-mouse max-scroll-amount="0%"
            // Hyprland's warp_on_change_workspace: the pointer follows
            // keyboard focus changes.
            warp-mouse-to-focus
        }

        ${vars.niriOutputSettings or ""}

        layout {
            gaps 8
            center-focused-column "never"
            // Hyprland's scrolling layout ran at column_width = 0.95.
            default-column-width { proportion 0.95; }
            preset-column-widths {
                proportion 0.33333
                proportion 0.5
                proportion 0.66667
                proportion 0.95
            }
            focus-ring {
                width 2
            }
            border {
                off
            }
            shadow {
                on
            }
        }

        // Ask apps for server-side decorations, as they get on Hyprland.
        prefer-no-csd

        // Hyprland's blur { size = 5; passes = 3; }. Both are dual kawase, and
        // Hyprland's size is the per-pass sample offset. If it shows banding
        // or blocky artifacts, raise passes rather than lowering offset.
        blur {
            passes 3
            offset 5
        }

        cursor {
            xcursor-theme "${cursor.name}"
            xcursor-size ${toString cursor.size}
        }

        spawn-at-startup "noctalia"

        hotkey-overlay {
            skip-at-startup
        }

        screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

        // niri's own switcher, also on Mod+Tab in place of noctalia's. A binds {}
        // section replaces all the defaults; Mod+Shift+Tab is left out because
        // it's the overview (binds.nix). Inside the switcher, arrows or H/L
        // move the selection and Enter confirms, without releasing the modifier.
        recent-windows {
            binds {
                Mod+Tab         { next-window; }
                Alt+Tab         { next-window; }
                Alt+Shift+Tab   { previous-window; }
                Alt+grave       { next-window     filter="app-id"; }
                Alt+Shift+grave { previous-window filter="app-id"; }
            }
        }

      ''

      # Written by noctalia's niri template: focus ring, border and switcher
      # colors. Last, so its layout {} values win. Optional because the file
      # only exists once noctalia has run with the template enabled.
      (lib.mkAfter ''
        include optional=true "noctalia.kdl"
      '')
    ];
  };
}
