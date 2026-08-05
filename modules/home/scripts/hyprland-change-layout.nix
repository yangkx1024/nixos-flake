{
  pkgs,
  hyprland,
}: let
  binPath = pkgs.lib.makeBinPath [
    hyprland
    pkgs.coreutils
    pkgs.jq
    pkgs.libnotify
  ];
in
  pkgs.writeShellScriptBin "hyprland-change-layout" ''
    set -euo pipefail
    export PATH=${binPath}:$PATH

    notif="''${XDG_CONFIG_HOME:-$HOME/.config}/swaync/images/catppuccin-macchiato.png"
    layouts=(dwindle master scrolling monocle)

    get_layout() {
      hyprctl -j getoption general:layout | jq -r '.str'
    }

    next_layout() {
      local current="$1"
      local i
      for i in "''${!layouts[@]}"; do
        if [[ "''${layouts[i]}" == "$current" ]]; then
          echo "''${layouts[((i + 1) % ''${#layouts[@]})]}"
          return
        fi
      done
      echo "''${layouts[0]}"
    }

    set_layout() {
      local target="$1"

      hyprctl keyword general:layout "$target"
      hyprctl keyword unbind SUPER,J || true
      hyprctl keyword unbind SUPER,K || true
      hyprctl keyword unbind SUPER,O || true
      hyprctl keyword unbind SUPER_SHIFT,M || true

      case "$target" in
      "dwindle")
        hyprctl keyword bind SUPER,J,cyclenext
        hyprctl keyword bind SUPER,K,cyclenext,prev
        hyprctl keyword bind SUPER,O,layoutmsg,togglesplit
        notify-send -e -u low -i "$notif" " Dwindle Layout"
        ;;
      "master")
        hyprctl keyword bind SUPER,J,layoutmsg,cyclenext
        hyprctl keyword bind SUPER,K,layoutmsg,cycleprev
        notify-send -e -u low -i "$notif" " Master Layout"
        ;;
      "scrolling")
        hyprctl keyword bind SUPER,J,cyclenext
        hyprctl keyword bind SUPER,K,cyclenext,prev
        notify-send -e -u low -i "$notif" " Scrolling Layout"
        ;;
      "monocle")
        hyprctl keyword bind SUPER,J,layoutmsg,cyclenext
        hyprctl keyword bind SUPER,K,layoutmsg,cycleprev
        hyprctl keyword bind SUPER_SHIFT,M,layoutmsg,swapnext
        notify-send -e -u low -i "$notif" " Monocle Layout"
        ;;
      *)
        echo "Unknown layout: $target" >&2
        return 1
        ;;
      esac
    }

    current="$(get_layout)"
    arg="''${1:-toggle}"

    case "$arg" in
    init)
      set_layout "$current"
      ;;
    toggle|next)
      set_layout "$(next_layout "$current")"
      ;;
    set)
      set_layout "''${2:-}"
      ;;
    master|dwindle|scrolling|monocle)
      set_layout "$arg"
      ;;
    *)
      echo "Usage: $(basename "$0") [toggle|next|init|set <layout>|master|dwindle|scrolling|monocle]" >&2
      exit 1
      ;;
    esac
  ''
