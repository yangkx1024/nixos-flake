{...}: {
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      "systemctl --user start hyprpolkitagent"
      "qs -c overview" # Start quickshell-overview daemon
      "hyprland-change-layout init"
      "noctalia-shell &"
    ];
  };
}
