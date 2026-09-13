{
  pkgs,
  inputs,
  ...
}: {
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      # noctalia's community "neovim" template renders ~/.config/nvim/lua/matugen.lua,
      # which drives base16-nvim and reloads itself on the SIGUSR1 its hook sends.
      # This is the same init its apply.sh appends when lazy.nvim isn't in use.
      # Note a non-empty `configure` makes the wrapper set VIMINIT, so a
      # ~/.config/nvim/init.lua would no longer be read.
      configure = {
        packages.noctalia.start = [pkgs.vimPlugins.base16-nvim];
        customLuaRC = ''
          local ok, matugen = pcall(require, 'matugen')
          if ok then matugen.setup() end
        '';
      };
    };
    hyprland = {
      enable = true; # set this so desktop file is created
      withUWSM = false;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
    dconf.enable = true;
    seahorse.enable = true;
    fuse.userAllowOther = true;
    mtr.enable = true;
    hyprlock.enable = true;
    localsend.enable = true; # also opens TCP/UDP 53317 so phones can send to this machine
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    matugen # color palette generator needed for noctalia-shell
    app2unit # launcher for noctalia-shell
    gpu-screen-recorder # needed for noctalia-shell screen-recorder plugin

    appimage-run # Needed For AppImage Support
    brightnessctl # For Screen Brightness Control
    cmatrix # Matrix Movie Effect In Terminal
    cowsay # Great Fun Terminal Program
    ddcutil # Monitor Control Over DDC/CI
    ffmpeg # Terminal Video / Audio Editing
    file-roller # Archive Manager
    gearlever # Manage / run Appimages
    icu # dep for gearlever
    killall # For Killing All Instances Of Programs
    libnotify # For Notifications
    lm_sensors # Used For Getting Hardware Temps
    lshw # Detailed Hardware Information
    mpv # Incredible Video Player
    papirus-icon-theme # icon theme
    bibata-cursors # cursor theme
    pavucontrol # For Editing Audio Levels & Devices
    pciutils # Collection Of Tools For Inspecting PCI Devices
    pkg-config # Wrapper Script For Allowing Packages To Get Info On Others
    playerctl # Allows Changing Media Volume Through Scripts
    ripgrep # Improved Grep
    socat # Needed For Screenshots
    unrar # Tool For Handling .rar Files
    unzip # Tool For Handling .zip Files
    usbutils # Good Tools For USB Devices
    # uwsm # Universal Wayland Session Manager (optional must be enabled)
    wget # Tool For Fetching Files With Links
    ytmdl # Tool For Downloading Audio From YouTube
    jq # JSON Processing

    python3
    zed-editor
    gnome-disk-utility
    google-chrome
    loupe
    wirelesstools
    efibootmgr
    nwg-look
    mission-center
    papers
    geary # Mail Client
    #foliate
    remmina
    codex
    claude-code
    herdr # Agent multiplexer for the terminal
  ];
}
