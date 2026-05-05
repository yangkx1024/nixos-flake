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
      (pkgs.stdenvNoCC.mkDerivation {
        pname = "misans-fonts";
        version = "1.0";

        src = ../../fonts/MiSans;

        installPhase = ''
          mkdir -p $out/share/fonts/truetype
          cp -v *.ttf $out/share/fonts/truetype/ 2>/dev/null || true

          mkdir -p $out/share/fonts/opentype
          cp -v *.otf $out/share/fonts/opentype/ 2>/dev/null || true
        '';
      })
    ];
    fontconfig.defaultFonts = {
      serif = ["MiSans" "Noto Serif" "Noto Serif CJK SC"];
      sansSerif = ["MiSans" "Noto Sans" "Noto Sans CJK SC"];
      monospace = ["Maple Mono NF CN" "JetBrainsMono Nerd Font"];
      emoji = ["Noto Color Emoji"];
    };
  };
}
