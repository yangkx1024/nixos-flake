{pkgs, ...}: {
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
    };
    hyprland = {
      enable = true; # set this so desktop file is created
      withUWSM = false;
    };
    dconf.enable = true;
    seahorse.enable = true;
    fuse.userAllowOther = true;
    mtr.enable = true;
    hyprlock.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    matugen # color palette generator needed for noctalia-shell
    app2unit # launcher for noctalia-shell
    gpu-screen-recorder # needed for nnoctalia-shell
    upower # noctalia shell battery

    alejandra # nix formatter
    appimage-run # Needed For AppImage Support
    brightnessctl # For Screen Brightness Control
    cliphist # Clipboard manager using rofi menu
    cmatrix # Matrix Movie Effect In Terminal
    cowsay # Great Fun Terminal Program
    eza # Beautiful ls Replacement
    ffmpeg # Terminal Video / Audio Editing
    file-roller # Archive Manager
    gearlever # Manage / run Appimages
    icu # dep for gearlever
    gpu-screen-recorder # needed for nnoctalia-shell
    power-profiles-daemon # needed for noctalia-shell power cycle
    killall # For Killing All Instances Of Programs
    libnotify # For Notifications
    lm_sensors # Used For Getting Hardware Temps
    lshw # Detailed Hardware Information
    mpv # Incredible Video Player
    papirus-icon-theme # icon theme
    pavucontrol # For Editing Audio Levels & Devices
    pciutils # Collection Of Tools For Inspecting PCI Devices
    pkg-config # Wrapper Script For Allowing Packages To Get Info On Others
    playerctl # Allows Changing Media Volume Through Scripts
    ripgrep # Improved Grep
    socat # Needed For Screenshots
    unrar # Tool For Handling .rar Files
    unzip # Tool For Handling .zip Files
    usbutils # Good Tools For USB Devices
    uwsm # Universal Wayland Session Manager (optional must be enabled)
    wget # Tool For Fetching Files With Links
    ytmdl # Tool For Downloading Audio From YouTube
  ];
}
