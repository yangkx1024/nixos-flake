{
  pkgs,
  config,
  ...
}: {
  home.packages = [
    (import ./screenshootin.nix {inherit pkgs;})
    (import ./restart.noctalia.nix {inherit pkgs;})
    (import ./hyprland-change-layout.nix {
      inherit pkgs;
      # The compositor's own build, so hyprctl always matches what is running
      hyprland = config.wayland.windowManager.hyprland.finalPackage;
    })
  ];
}
