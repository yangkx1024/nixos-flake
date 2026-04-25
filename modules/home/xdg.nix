{
  config,
  pkgs,
  ...
}: {
  home.file = {
    ".local/share/fonts/MiSans".source = ../../fonts/MiSans;
  };
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };
  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "image/jpeg" = ["org.gnome.Loupe.desktop"];
        "image/png" = ["org.gnome.Loupe.desktop"];
        "image/gif" = ["org.gnome.Loupe.desktop"];
        "image/webp" = ["org.gnome.Loupe.desktop"];
        "text/html" = ["com.google.Chrome.desktop"];
        "x-scheme-handler/http" = ["com.google.Chrome.desktop"];
        "x-scheme-handler/https" = ["com.google.Chrome.desktop"];
        "x-scheme-handler/about" = ["com.google.Chrome.desktop"];
        "application/pdf" = ["org.gnome.Papers.desktop"];
      };
    };
    portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
      configPackages = [pkgs.hyprland];
    };
    configFile."qt5ct/qt5ct.conf".text = ''
      [Appearance]
      color_scheme_path=${config.xdg.configHome}/qt5ct/colors/noctalia.conf
      custom_palette=true
      icon_theme=Papirus-Dark

      [Fonts]
      fixed="Maple Mono NF CN,12,-1,5,50,0,0,0,0,0,Regular"
      general="MiSans,12,-1,5,50,0,0,0,0,0"
    '';
    configFile."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      color_scheme_path=${config.xdg.configHome}/qt6ct/colors/noctalia.conf
      custom_palette=true
      icon_theme=Papirus-Dark

      [Fonts]
      fixed="Maple Mono NF CN,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
      general="MiSans,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    '';
    configFile."gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-theme-name=Adwaita
      gtk-icon-theme-name=Papirus-Dark
      gtk-font-name=MiSans 12
      gtk-cursor-theme-name=Bibata-Modern-Ice
      gtk-cursor-theme-size=24
      gtk-application-prefer-dark-theme=1
    '';
    configFile."gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-theme-name=Adwaita
      gtk-icon-theme-name=Papirus-Dark
      gtk-font-name=MiSans 12
      gtk-cursor-theme-name=Bibata-Modern-Ice
      gtk-cursor-theme-size=24
      gtk-application-prefer-dark-theme=1
    '';
  };
}
