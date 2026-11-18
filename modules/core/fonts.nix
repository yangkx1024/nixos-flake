{pkgs, ...}: {
  # services.flatpak forces fonts.fontDir.enable, which defaults
  # programs.xwayland.defaultFontPath to /run/current-system/sw/share/X11/fonts.
  # That override rebuilds Xwayland from source on every update since the binary
  # cache only has the stock build. Empty restores the cached one; only legacy
  # X11 core-font clients care, modern apps go through fontconfig.
  programs.xwayland.defaultFontPath = "";

  fonts = {
    packages = with pkgs; [
      font-awesome
      material-icons
      maple-mono.NF-CN
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-monochrome-emoji
      terminus_font
    ];
    fontconfig.defaultFonts = {
      serif = ["Noto Serif" "Noto Serif CJK SC"];
      sansSerif = ["Noto Sans" "Noto Sans CJK SC"];
      monospace = ["Maple Mono NF CN" "JetBrainsMono Nerd Font"];
      emoji = ["Noto Color Emoji"];
    };
  };
}
