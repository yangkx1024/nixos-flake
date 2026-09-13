{...}: {
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
  console.keyMap = "us";
  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 50;
  };
  system.stateVersion = "26.05";
}
