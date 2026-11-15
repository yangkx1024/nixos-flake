{pkgs, ...}: {
  nix = {
    # Dedup the store on a timer (Persistent, idle IO) instead of hashing every
    # file inline on each store write, which made writes ~50% slower.
    optimise.automatic = true;
    settings = {
      download-buffer-size = 200000000;
      flake-registry = "";
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
  time.timeZone = "Asia/Singapore";
  i18n = {
    defaultLocale = "zh_SG.UTF-8";
    extraLocales = [
      "zh_CN.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      LC_ADDRESS = "zh_SG.UTF-8";
      LC_IDENTIFICATION = "zh_SG.UTF-8";
      LC_MEASUREMENT = "zh_SG.UTF-8";
      LC_MONETARY = "zh_SG.UTF-8";
      LC_NAME = "zh_SG.UTF-8";
      LC_NUMERIC = "zh_SG.UTF-8";
      LC_PAPER = "zh_SG.UTF-8";
      LC_TELEPHONE = "zh_SG.UTF-8";
      LC_TIME = "zh_SG.UTF-8";
    };
  };
  console = {
    keyMap = "us";
    # Bold Terminus 16x32, crisper than the kernel's built-in 16x32 at 4K.
    # The 256-glyph "u" set, not the 512-glyph "v": a 512-glyph font takes the
    # VT's intensity bit, leaving 8 colours (bootvine then switches to its
    # 8-colour palette); bootvine falls back to x and ... for × and …. Nothing
    # taller than 32px: vconsole-setup reads the font with KD_FONT_OP_GET,
    # which fails (ENOSPC) above 32 rows, so spleen-32x64 failed the unit on
    # every boot. earlySetup puts the font in the initrd so bootvine uses it
    # from the first frame.
    earlySetup = true;
    packages = [pkgs.terminus_font];
    font = "ter-u32b";
    # Gruvbox Dark, the palette bootvine's own sample machines use
    # (vm-tests/shared/common.nix). Becomes vt.default_{red,grn,blu} kernel
    # params, so it holds from the first frame.
    colors = [
      "1d2021"
      "fb4934"
      "b8bb26"
      "fabd2f"
      "83a598"
      "d3869b"
      "8ec07c"
      "d5c4a1"
      "665c54"
      "fb4934"
      "b8bb26"
      "fabd2f"
      "83a598"
      "d3869b"
      "8ec07c"
      "fbf1c7"
    ];
  };
  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 50;
  };
  system.stateVersion = "26.05";
}
