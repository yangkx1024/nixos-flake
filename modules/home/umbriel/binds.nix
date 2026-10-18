{
  vars,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (vars)
    browser
    terminal
    ;
  # Same keys as modules/home/niri/binds.nix, plus Hyprland's special
  # workspace (as the default scratchpad), layout switcher and edit keys,
  # which niri lacks. Not ported: the window screenshot (no screenshot UI;
  # grim can't pick a window here).
  # Setting keybinds replaces every built-in bind. Umbriel's built-in
  # touchpad gestures and Mod+drag move/resize work without one.
  noctalia = args: "spawn:noctalia msg ${args}";
  shots = "$HOME/Pictures/Screenshots/Screenshot from $(date +'%Y-%m-%d %H-%M-%S').png";
  once = action: {
    inherit action;
    repeat = false;
  };
  locked = action: {
    inherit action;
    allow_when_locked = true;
  };

  # Hyprland's macOS-style edit keys (hyprland/binds.nix). Umbriel has no
  # send-shortcut action, so wtype types the shortcut through a virtual
  # keyboard; Umbriel keeps each keyboard's modifiers apart, so the app sees
  # CTRL alone even with SUPER still held. Terminals get CTRL+SHIFT for copy,
  # paste and select-all, and nothing for cut, undo and save, whose CTRL forms
  # are SIGINT-like there (readline prefix, SIGTSTP, XOFF).
  editKey = pkgs.writeShellApplication {
    name = "umbriel-edit-key";
    runtimeInputs = [pkgs.socat pkgs.jq pkgs.wtype];
    # The IPC socket directly: `umbriel windows` loads the whole compositor
    # binary first, about 11ms of this script's 20ms.
    text = ''
      key=$1
      sock=''${UMBRIEL_SOCKET:-$XDG_RUNTIME_DIR/umbriel-$WAYLAND_DISPLAY.sock}
      if echo '{"cmd":"windows"}' | socat -t 1 STDIO "UNIX-CONNECT:$sock" \
        | jq -e --arg re ${lib.escapeShellArg (import ./terminals.nix)} \
          'any(.ok[]; .focused and (.app_id | test($re)))' >/dev/null; then
        case $key in
          c | v | a) exec wtype -M ctrl -M shift -k "$key" -m shift -m ctrl ;;
          *) exit 0 ;;
        esac
      fi
      exec wtype -M ctrl -k "$key" -m ctrl
    '';
  };
in {
  programs.umbriel.settings.keybinds =
    {
      "Mod+Shift+Slash" = once "cheatsheet-toggle";

      # ============= NOCTALIA =============
      "Mod+Space" = noctalia "panel-toggle launcher";
      "Mod+M" = noctalia "panel-toggle control-center notifications";
      "Mod+Shift+V" = noctalia "panel-toggle clipboard";
      "Mod+Alt+P" = noctalia "settings-toggle";
      "Mod+Comma" = noctalia "settings-toggle";
      "Mod+Ctrl+L" = noctalia "session lock";
      "Mod+Shift+W" = noctalia "panel-toggle wallpaper";
      "Mod+Shift+X" = noctalia "panel-toggle session";
      "Mod+N" = noctalia "panel-toggle control-center";
      "Mod+Shift+R" = "spawn:pkill -x noctalia; sleep 0.3; noctalia";
      # Noctalia's switcher, as on Hyprland; Umbriel has none of its own.
      "Mod+Tab" = noctalia "window-switcher";
      "Alt+Tab" = noctalia "window-switcher";

      # ============= APPS =============
      # app2unit starts each app in its own scope under app.slice, as
      # noctalia's launcher does.
      "Mod+Return" = "spawn:app2unit -- ${terminal}";
      "Mod+B" = "spawn:app2unit -- ${browser}";
      "Mod+T" = "spawn:app2unit -- thunar";
      "Mod+Alt+M" = "spawn:pavucontrol";

      # ============= SCREENSHOTS =============
      "Mod+G" = "spawn:screenshootin";
      "Mod+Ctrl+G" = ''spawn:grim "${shots}"'';
      "Mod+Alt+G" = ''spawn:grim -g "$(slurp)" "${shots}"'';
      "Mod+Alt+C" = "spawn:hyprpicker -a";

      # ============= MACOS-STYLE EDIT KEYS =============
      "Mod+C" = once "spawn:${lib.getExe editKey} c";
      "Mod+V" = once "spawn:${lib.getExe editKey} v";
      "Mod+X" = once "spawn:${lib.getExe editKey} x";
      "Mod+A" = once "spawn:${lib.getExe editKey} a";
      "Mod+Z" = once "spawn:${lib.getExe editKey} z";
      "Mod+S" = once "spawn:${lib.getExe editKey} s";

      # ============= WINDOWS =============
      "Mod+Q" = once "window-close";
      "Mod+F" = once "window-toggle-fullscreen";
      "Mod+Shift+F" = once "window-toggle-floating";
      "Mod+Ctrl+F" = once "window-toggle-maximize";
      "Mod+P" = once "window-toggle-pinned";
      "Mod+Shift+C" = "session-quit";
      "Mod+Escape" = (once "shortcuts-inhibit-toggle") // {allow_when_inhibited = true;};

      # Hyprspace's overview key
      "Mod+Shift+Tab" = once "overview-toggle";

      # ============= SCRATCHPAD =============
      # Hyprland's special workspace.
      "Mod+0" = "scratchpad-toggle";
      "Mod+Shift+0" = once "window-toggle-scratchpad";

      # ============= LAYOUTS =============
      # Per workspace, as Hyprland's hyprland-change-layout.
      "Mod+Alt+L" = "workspace-set-layout:toggle";
      "Mod+Alt+1" = "workspace-set-layout:dwindle";
      "Mod+Alt+2" = "workspace-set-layout:master";
      "Mod+Alt+3" = "workspace-set-layout:scrolling";
      # Refused outside dwindle, like Hyprland's layout messages.
      "Mod+O" = "layout-toggle-split";
      "Mod+Shift+M" = "window-swap-next";

      # ============= COLUMNS =============
      "Mod+R" = "window-cycle-primary-extent";
      "Mod+Minus" = "window-modify-primary-extent:-0.1";
      "Mod+Equal" = "window-modify-primary-extent:0.1";
      "Mod+Shift+Minus" = "window-modify-secondary-extent:-0.1";
      "Mod+Shift+Equal" = "window-modify-secondary-extent:0.1";
      "Mod+BracketLeft" = "window-consume-or-expel-left";
      "Mod+BracketRight" = "window-consume-or-expel-right";
      "Mod+W" = once "column-toggle-tabbed";

      # ============= FOCUS =============
      "Mod+Left" = "window-focus-left";
      "Mod+Right" = "window-focus-right";
      "Mod+Up" = "window-focus-up";
      "Mod+Down" = "window-focus-down";
      "Mod+H" = "window-focus-left";
      "Mod+L" = "window-focus-right";
      "Mod+K" = "window-focus-up";
      "Mod+J" = "window-focus-down";

      # ============= MOVE =============
      "Mod+Shift+Left" = "column-move-left";
      "Mod+Shift+Right" = "column-move-right";
      "Mod+Shift+Up" = "window-move-up";
      "Mod+Shift+Down" = "window-move-down";
      "Mod+Shift+H" = "column-move-left";
      "Mod+Shift+L" = "column-move-right";
      "Mod+Shift+K" = "window-move-up";
      "Mod+Shift+J" = "window-move-down";

      # ============= SWAP =============
      # Arrows only: Mod+Alt+L is the layout toggle, as on Hyprland.
      "Mod+Alt+Left" = "window-swap-left";
      "Mod+Alt+Right" = "window-swap-right";
      "Mod+Alt+Up" = "window-swap-up";
      "Mod+Alt+Down" = "window-swap-down";

      # ============= WORKSPACES =============
      # Per monitor, stacked vertically, as on niri.
      "Mod+Ctrl+Right" = "workspace-next";
      "Mod+Ctrl+Left" = "workspace-previous";
      "Mod+WheelDown" = {
        action = "workspace-next";
        cooldown_ms = 150;
      };
      "Mod+WheelUp" = {
        action = "workspace-previous";
        cooldown_ms = 150;
      };
      "Mod+Shift+WheelDown" = "window-focus-right";
      "Mod+Shift+WheelUp" = "window-focus-left";

      # ============= MEDIA & HARDWARE =============
      "XF86AudioRaiseVolume" = locked "spawn:wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
      "XF86AudioLowerVolume" = locked "spawn:wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      "XF86AudioMute" = locked "spawn:wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      "XF86AudioPlay" = locked "spawn:playerctl play-pause";
      "XF86AudioPause" = locked "spawn:playerctl play-pause";
      "XF86AudioNext" = locked "spawn:playerctl next";
      "XF86AudioPrev" = locked "spawn:playerctl previous";
      "XF86MonBrightnessDown" = locked "spawn:brightnessctl set 5%-";
      "XF86MonBrightnessUp" = locked "spawn:brightnessctl set +5%";
    }
    // lib.mergeAttrsList (map (i: {
      "Mod+${i}" = "workspace-switch:${i}";
      "Mod+Shift+${i}" = "column-move-to-workspace:${i}";
    }) (map toString (lib.range 1 9)));
}
