{...}: {
  hardware = {
    graphics.enable = true;
    enableRedistributableFirmware = true;
    i2c.enable = true; # DDC/CI for monitor control via ddcutil
    keyboard.qmk.enable = true;
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
  };
  local.hardware-clock.enable = false;
}
