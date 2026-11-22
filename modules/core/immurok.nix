{
  config,
  pkgs,
  ...
}: let
  immurok = pkgs.callPackage ../../pkgs/immurok.nix {};
  pamModule = "${immurok}/lib/security/pam_immurok.so";
in {
  # immurok BLE fingerprint key: touch the sensor instead of typing the
  # password for sudo and polkit. https://github.com/immurok/app-linux-rs
  environment.systemPackages = [immurok];

  services.dbus.packages = [immurok];

  users = {
    users.immurok = {
      isSystemUser = true;
      group = "immurok";
      description = "immurok fingerprint daemon";
    };
    groups.immurok = {};
  };

  systemd = {
    packages = [immurok];
    services.immurok-daemon.wantedBy = ["multi-user.target"];
    user.services.immurok-session-agent.wantedBy = ["default.target"];
    tmpfiles.rules = ["d /run/immurok 0755 immurok immurok -"];
  };

  # The app's PAM page edits /etc/pam.d, which NixOS generates; the rules live
  # here instead. Ahead of the YubiKey: with the fingerprint key disconnected
  # the daemon answers NOT_CONNECTED at once and sudo moves on to pam_u2f.
  security.pam.services = {
    sudo.rules.auth.immurok = {
      order = config.security.pam.services.sudo.rules.auth.u2f.order - 10;
      control = "sufficient";
      modulePath = pamModule;
    };
    polkit-1.rules.auth.immurok = {
      order = config.security.pam.services.polkit-1.rules.auth.u2f.order - 10;
      control = "sufficient";
      modulePath = pamModule;
      args = ["timeout=10"];
    };
  };
}
