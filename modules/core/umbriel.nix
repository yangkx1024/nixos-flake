{
  inputs,
  pkgs,
  ...
}: {
  # Session next to Hyprland; noctalia-greeter's session picker lists both
  # and remembers the last one. The flake's module replaces nixpkgs'
  # programs.umbriel and defaults the package and xdg-desktop-portal-umbriel
  # (screencast, screenshot; preferred over gtk) to the flake's builds.
  imports = [inputs.umbriel.nixosModules.default];

  programs.umbriel.enable = true;

  # Neither umbriel's portal nor gtk implements Background, so autostart and
  # background-permission requests fail; take it from the GNOME portal. This
  # merges into the module's config.umbriel (default = umbriel;gtk).
  xdg.portal = {
    extraPortals = [pkgs.xdg-desktop-portal-gnome];
    config.umbriel."org.freedesktop.impl.portal.Background" = "gnome";
  };

  # libgxdp only brings up its Wayland connection when GDK_BACKEND is unset or
  # exactly "wayland"; the session's "wayland,x11" (modules/home/session-env.nix)
  # drops the GNOME portal to "exposing settings only", without Background.
  # enableDefaultPath would also pin PATH to coreutils & co. in the override,
  # hiding the session PATH the portal inherits today.
  systemd.user.services.xdg-desktop-portal-gnome = {
    environment.GDK_BACKEND = "wayland";
    enableDefaultPath = false;
  };
}
