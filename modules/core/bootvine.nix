{inputs, ...}: {
  # Live tree of pending systemd jobs on tty12, from the systemd initrd through
  # stage 2 until noctalia-greeter takes its VT; also shown at shutdown.
  # `bootvine defaults --format nix` lists the keys for services.bootvine.settings.
  imports = [inputs.bootvine.nixosModules.default];

  services.bootvine.enable = true;
}
