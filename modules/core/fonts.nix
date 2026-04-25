{pkgs, ...}: {
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
  };
}
