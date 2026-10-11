{inputs, ...}: {
  # Tells you what each USB cable / device can actually do (USB-C PD, e-marker,
  # link speed). https://github.com/yangkx1024/usbeehive
  imports = [
    inputs.usbeehive.nixosModules.default
  ];

  programs.usbeehive.enable = true;
}
