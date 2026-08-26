{inputs, ...}: {
  # Local-first replacement for Logitech Options+: HID++ button remapping,
  # DPI/gesture control and UVC webcam controls.
  # https://github.com/AprilNEA/OpenLogi
  imports = [
    inputs.openlogi.nixosModules.default
  ];

  programs.openlogi = {
    enable = true;
    # The agent is a systemd user unit bound to graphical-session.target, which
    # Hyprland's home-manager systemd integration activates.
    launchAtLogin = true;
  };
}
