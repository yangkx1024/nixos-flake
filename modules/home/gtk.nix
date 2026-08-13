{pkgs, ...}: {
  # middle-click paste. GTK apps (ghostty, chrome) read this from gsettings,
  # and the org.gnome.desktop.interface schema defaults it to false, which
  # disables middle-click paste for every GTK app on the system.
  dconf.settings."org/gnome/desktop/interface".gtk-enable-primary-paste = true;

  gtk = {
    gtk4.theme = null;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };
}
