{pkgs, ...}: {
  home.packages = [
    (import ./screenshootin.nix {inherit pkgs;})
    (import ./restart.noctalia.nix {inherit pkgs;})
    (import ./hyprland-change-layout.nix {inherit pkgs;})
  ];
}
