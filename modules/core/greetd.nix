{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.noctalia-greeter.nixosModules.default];

  programs.noctalia-greeter = {
    enable = true;
    # greeter-args left at default "" → session picker, remembers last choice.

    # Upstream decodes the avatar at its logical size (~64px), so it is upscaled
    # and blurry on HiDPI outputs; the patch decodes at buffer resolution.
    # Drop once upstream fixes GreeterSurface::syncHeaderUserAvatar.
    package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      patches = (old.patches or []) ++ [../../patches/noctalia-greeter-hidpi-avatar.patch];
    });
  };
}
