{
  vars,
  config,
  pkgs,
  ...
}: {
  # Desktop pieces every compositor session uses, kept out of the hyprland/,
  # niri/ and umbriel/ modules so dropping a compositor doesn't take them along.

  # environment.d, read by the systemd user manager. niri.service and
  # umbriel.service take their environment from it, as do the apps noctalia
  # launches as systemd units (launch_apps_as_systemd_services).
  systemd.user.sessionVariables = import ./session-env.nix {
    inherit vars;
    cursor = config.home.pointerCursor;
  };

  home.packages = with pkgs; [
    # screenshootin (scripts/screenshootin.nix); swappy's config is swappy.nix
    grim
    slurp
    swappy
    # Color picker on SUPER+ALT+C in both sessions.
    hyprpicker
  ];

  # Avatar: ~/.face.icon for greeters and toolkits that look for it, and
  # ~/.config/face.jpg for noctalia's shell.avatar_path. The AccountsService
  # icon (modules/core/user.nix) links the same file.
  home.file = {
    ".face.icon".source = ./face.jpg;
    ".config/face.jpg".source = ./face.jpg;
  };
}
