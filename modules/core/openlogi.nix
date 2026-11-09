{inputs, ...}: {
  # Local-first replacement for Logitech Options+: HID++ button remapping,
  # DPI/gesture control and UVC webcam controls.
  # https://github.com/AprilNEA/OpenLogi
  imports = [
    inputs.openlogi.nixosModules.default
  ];

  # nixpkgs ships its own programs.openlogi module (0.6.25, no agent service)
  # that collides with the flake's. Keep the flake's (0.9.x + launchAtLogin).
  disabledModules = ["programs/openlogi.nix"];

  programs.openlogi = {
    enable = true;
    # The agent is a systemd user unit bound to graphical-session.target, which
    # Hyprland's home-manager systemd integration activates.
    launchAtLogin = true;
  };
}
