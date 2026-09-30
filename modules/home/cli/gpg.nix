_: {
  programs.gpg = {
    enable = true;
    # pcscd owns the CCID interface; make scdaemon use PC/SC instead of its
    # built-in CCID driver so GnuPG and YubiKey tooling use the same backend.
    scdaemonSettings.disable-ccid = true;
  };
}
