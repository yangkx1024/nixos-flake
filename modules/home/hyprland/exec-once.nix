{...}: {
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
      hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
      hl.exec_cmd("systemctl --user start hyprpolkitagent")
      hl.exec_cmd("qs -c overview")
      hl.exec_cmd("hyprland-change-layout init")
      hl.exec_cmd("noctalia-shell &")
    end)
  '';
}
