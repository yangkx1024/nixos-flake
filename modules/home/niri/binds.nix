{
  vars,
  lib,
  ...
}: let
  inherit
    (vars)
    browser
    terminal
    ;
  # Same keys as modules/home/hyprland/binds.nix wherever niri has an
  # equivalent. Not ported: the SUPER+C/V/X/A/Z/S edit keys (niri has no
  # per-app binds or send-shortcut), the special workspace (no scratchpad),
  # the layout switcher, pseudo/togglesplit/swapnext and float-all.
  # Mod+left/right drag moves and resizes windows without a bind.
  noctalia = args: ''spawn "noctalia" "msg" ${args}'';
in {
  wayland.windowManager.niri.extraConfig = ''
    binds {
        Mod+Shift+Slash { show-hotkey-overlay; }

        // ============= NOCTALIA =============
        Mod+Space       { ${noctalia ''"panel-toggle" "launcher"''}; }
        Mod+M           { ${noctalia ''"panel-toggle" "control-center" "notifications"''}; }
        Mod+Shift+V     { ${noctalia ''"panel-toggle" "clipboard"''}; }
        Mod+Alt+P       { ${noctalia ''"settings-toggle"''}; }
        Mod+Comma       { ${noctalia ''"settings-toggle"''}; }
        Mod+Ctrl+L      { ${noctalia ''"session" "lock"''}; }
        Mod+Shift+W     { ${noctalia ''"panel-toggle" "wallpaper"''}; }
        Mod+Shift+X     { ${noctalia ''"panel-toggle" "session"''}; }
        Mod+N           { ${noctalia ''"panel-toggle" "control-center"''}; }
        Mod+Shift+R     { spawn-sh "pkill -x noctalia; sleep 0.3; noctalia"; }

        // ============= APPS =============
        // app2unit starts each app in its own scope under app.slice, as
        // noctalia's launcher does.
        Mod+Return      { spawn "app2unit" "--" "${terminal}"; }
        Mod+B           { spawn "app2unit" "--" "${browser}"; }
        Mod+T           { spawn "app2unit" "--" "thunar"; }
        Mod+Alt+M       { spawn "pavucontrol"; }

        // ============= SCREENSHOTS =============
        // niri's own screenshot UI replaces hyprshot, which needs hyprctl.
        Mod+G           { spawn "screenshootin"; }
        Mod+Ctrl+G      { screenshot-screen; }
        Mod+Shift+G     { screenshot-window; }
        Mod+Alt+G       { screenshot; }
        Mod+Alt+C       { spawn "hyprpicker" "-a"; }

        // ============= WINDOWS =============
        Mod+Q repeat=false { close-window; }
        Mod+F           { fullscreen-window; }
        Mod+Shift+F     { toggle-window-floating; }
        Mod+Ctrl+F      { maximize-column; }
        Mod+Shift+C     { quit; }
        Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

        // Hyprspace's overview key
        Mod+Shift+Tab repeat=false { toggle-overview; }

        // ============= COLUMNS =============
        Mod+R           { switch-preset-column-width; }
        Mod+Minus       { set-column-width "-10%"; }
        Mod+Equal       { set-column-width "+10%"; }
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }
        Mod+BracketLeft  { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }
        Mod+W           { toggle-column-tabbed-display; }

        // ============= FOCUS =============
        Mod+Left        { focus-column-left; }
        Mod+Right       { focus-column-right; }
        Mod+Up          { focus-window-up; }
        Mod+Down        { focus-window-down; }
        Mod+H           { focus-column-left; }
        Mod+L           { focus-column-right; }
        Mod+K           { focus-window-up; }
        Mod+J           { focus-window-down; }

        // ============= MOVE =============
        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Up    { move-window-up; }
        Mod+Shift+Down  { move-window-down; }
        Mod+Shift+H     { move-column-left; }
        Mod+Shift+L     { move-column-right; }
        Mod+Shift+K     { move-window-up; }
        Mod+Shift+J     { move-window-down; }

        // ============= SWAP =============
        Mod+Alt+Left    { swap-window-left; }
        Mod+Alt+Right   { swap-window-right; }
        Mod+Alt+Up      { move-window-up; }
        Mod+Alt+Down    { move-window-down; }
        Mod+Alt+H       { swap-window-left; }
        Mod+Alt+L       { swap-window-right; }
        Mod+Alt+K       { move-window-up; }
        Mod+Alt+J       { move-window-down; }

        // ============= WORKSPACES =============
        // niri stacks workspaces vertically, one stack per monitor.
    ${lib.concatMapStrings (i: ''
      Mod+${i} { focus-workspace ${i}; }
      Mod+Shift+${i} { move-column-to-workspace ${i}; }
    '') (map toString (lib.range 1 9))}
        Mod+Ctrl+Right  { focus-workspace-down; }
        Mod+Ctrl+Left   { focus-workspace-up; }
        Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
        Mod+WheelScrollUp   cooldown-ms=150 { focus-workspace-up; }
        Mod+Shift+WheelScrollDown { focus-column-right; }
        Mod+Shift+WheelScrollUp   { focus-column-left; }

        // ============= MEDIA & HARDWARE =============
        XF86AudioRaiseVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
        XF86AudioLowerVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
        XF86AudioMute         allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86AudioPlay         allow-when-locked=true { spawn "playerctl" "play-pause"; }
        XF86AudioPause        allow-when-locked=true { spawn "playerctl" "play-pause"; }
        XF86AudioNext         allow-when-locked=true { spawn "playerctl" "next"; }
        XF86AudioPrev         allow-when-locked=true { spawn "playerctl" "previous"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "5%-"; }
        XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "set" "+5%"; }
    }
  '';
}
