{inputs, ...}: {
  # Trial session next to Hyprland and niri; noctalia-greeter's session picker
  # lists it. The flake's module replaces nixpkgs' programs.umbriel and
  # defaults the package and xdg-desktop-portal-umbriel (screencast,
  # screenshot; preferred over gtk) to the flake's builds.
  imports = [inputs.umbriel.nixosModules.default];

  programs.umbriel.enable = true;
}
