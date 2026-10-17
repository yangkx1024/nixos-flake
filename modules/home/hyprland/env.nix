{
  vars,
  config,
  lib,
  ...
}: let
  envPair = name: value: {_args = [name value];};
  cursor = config.home.pointerCursor;
in {
  # Hyprland passes these to its children, and hyprland.nix's
  # systemd.variables = ["--all"] exports them to systemd user and D-Bus
  # activated services. The shared part lives in ../session-env.nix.
  wayland.windowManager.hyprland.settings.env = lib.mapAttrsToList envPair (
    import ../session-env.nix {inherit vars cursor;}
    // {
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      HYPRCURSOR_THEME = cursor.name;
      HYPRCURSOR_SIZE = toString cursor.size;
    }
  );
}
