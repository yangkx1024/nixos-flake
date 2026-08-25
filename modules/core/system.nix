{pkgs, ...}: {
  nix = {
    settings = {
      download-buffer-size = 200000000;
      auto-optimise-store = true;
      flake-registry = "";
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
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
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      qt6Packages.fcitx5-chinese-addons
      fcitx5-nord
    ];
  };
  environment.variables = {
    NIXOS_OZONE_WL = "1";
  };
  console.keyMap = "us";
  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 50;
  };
  system.stateVersion = "26.05";
}
