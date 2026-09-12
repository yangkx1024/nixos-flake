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

    # Hyprland 0.56 removed `hyprctl keyword` along with the hyprlang config.
    # The replacement is `hyprctl eval`, which runs Lua against the live config,
    # so setting a layout is hl.config({general = {layout = ...}}). general:layout
    # is declared with .refresh = REFRESH_LAYOUTS in Hyprland's
    # src/config/values/ConfigValues.cpp, which makes the prop refresher re-run
    # updateWorkspaceLayouts() and re-tile every workspace on its own — `hyprctl -r`
    # is not needed.
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
      local target="''${1:-}"

      # Validate before handing the name to the compositor. hl.config accepts any
      # string for general:layout without complaint (exit 0, "ok"), stores the
      # garbage, and silently falls back to tiling with dwindle — so an unchecked
      # typo here would quietly change the layout to the wrong one.
      local known=0 l
      for l in "''${layouts[@]}"; do
        [[ "$l" == "$target" ]] && known=1 && break
      done
      if ((known == 0)); then
        echo "Unknown layout: ''${target:-<none>} (expected one of: ''${layouts[*]})" >&2
        return 1
      fi

      hyprctl eval "hl.config({ general = { layout = \"$target\" } })" >/dev/null

      # Read back rather than trusting the call. hyprctl exits 0 for requests the
      # compositor does not understand, which is exactly how the previous
      # `hyprctl keyword` implementation of this script kept reporting success
      # while doing nothing for an entire Hyprland release.
      local now
      now="$(get_layout)"
      if [[ "$now" != "$target" ]]; then
        echo "Failed to set layout to $target (still $now)" >&2
        return 1
      fi

      notify-send -e -u low "Layout: $target"
    }

    arg="''${1:-toggle}"

    case "$arg" in
    toggle | next)
      set_layout "$(next_layout "$(get_layout)")"
      ;;
    set)
      set_layout "''${2:-}"
      ;;
    dwindle | master | scrolling | monocle)
      set_layout "$arg"
      ;;
    *)
      echo "Usage: $(basename "$0") [toggle|next|set <layout>|dwindle|master|scrolling|monocle]" >&2
      exit 1
      ;;
    esac
  ''
