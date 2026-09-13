{
  pkgs,
  config,
  ...
}: {
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
      hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
      -- Xwayland reports a fake 96 DPI, so X11 clients need Xft.dpi to match
      -- DP-1's scale (see xresources.properties in hyprland.nix). Xwayland may
      -- not have claimed its socket yet at this point, so wait for it rather
      -- than racing it.
      hl.exec_cmd("bash -c 'for i in $(seq 1 50); do ${pkgs.xrdb}/bin/xrdb -merge ${config.xresources.path} && break; sleep 0.2; done'")
      hl.exec_cmd("noctalia")
    end)
  '';
}
