# Toolkit hints shared by every compositor session. Not a module: hyprland/env.nix
# puts them in Hyprland's env, niri/config.nix in systemd.user.sessionVariables.
# Don't repeat these in NixOS environment.{variables,sessionVariables} or
# home.sessionVariables. cursor is config.home.pointerCursor.
{
  vars,
  cursor,
}: {
  NIXOS_OZONE_WL = "1";
  NIXPKGS_ALLOW_UNFREE = "1";
  XDG_SESSION_TYPE = "wayland";
  GDK_BACKEND = "wayland,x11";
  CLUTTER_BACKEND = "wayland";
  QT_QPA_PLATFORM = "wayland;xcb";
  QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  MOZ_ENABLE_WAYLAND = "1";
  # This is to make electron apps start in wayland
  ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  EDITOR = "nvim";
  TERMINAL = vars.terminal;
  XDG_TERMINAL_EMULATOR = vars.terminal;
  XCURSOR_THEME = cursor.name;
  XCURSOR_SIZE = toString cursor.size;
}
