{pkgs, ...}: {
  # YubiKey support: ykman needs pcscd for the CCID applets (OATH, PIV, OpenPGP);
  # FIDO/U2F goes over hidraw, which the yubikey-personalization udev rules open up.
  services = {
    pcscd.enable = true;
    udev.packages = [pkgs.yubikey-personalization];
  };

  # Touch the YubiKey instead of typing the password for sudo. Enabled only for
  # sudo: the global u2f.enable would also cover greetd login, where a touch
  # login leaves the GNOME keyring locked (it unlocks from the typed password).
  # "sufficient": with the key unplugged, sudo falls back to the password.
  # Register the key once with: pamu2fcfg > ~/.config/Yubico/u2f_keys
  security.pam = {
    u2f.settings.cue = true; # print "Please touch the device"
    services.sudo.u2f.enable = true;
  };

  environment.systemPackages = with pkgs; [
    yubikey-manager # ykman CLI
    yubioath-flutter # Yubico Authenticator GUI (successor to yubikey-manager-qt)
    pam_u2f # pamu2fcfg, to register the key
  ];
}
