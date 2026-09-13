{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.noctalia-greeter.nixosModules.default];

  services.displayManager.noctalia-greeter = {
    enable = true;
    # greeter-args left at default "" → session picker, remembers last choice.

    # Upstream decodes the avatar at its logical size (~64px), so it is upscaled
    # and blurry on HiDPI outputs; the patch decodes at buffer resolution.
    # Drop once upstream fixes GreeterSurface::syncHeaderUserAvatar.
    package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      patches = (old.patches or []) ++ [../../patches/noctalia-greeter-hidpi-avatar.patch];
    });

    # Sets settings.cursor.path to the package's share/icons. Non-empty settings
    # make greeter.toml a store symlink; session/scheme memory lives in sync.toml.
    cursorTheme.package = pkgs.bibata-cursors;
    settings.cursor = {
      theme = "Bibata-Modern-Ice";
      size = 24;
    };
  };
}
