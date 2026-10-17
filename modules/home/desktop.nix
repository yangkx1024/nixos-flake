{pkgs, ...}: {
  # Desktop pieces every compositor session uses, kept out of the hyprland/
  # and niri/ modules so dropping either compositor doesn't take them along.

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
