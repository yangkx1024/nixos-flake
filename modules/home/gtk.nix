{pkgs, ...}: {
  # middle-click paste. GTK apps (ghostty, chrome) read this from gsettings,
  # and the org.gnome.desktop.interface schema defaults it to false, which
  # disables middle-click paste for every GTK app on the system.
  dconf.settings."org/gnome/desktop/interface".gtk-enable-primary-paste = true;

  # This module owns ~/.config/gtk-{3,4}.0/settings.ini outright. Do not also
  # write that path through xdg.configFile: the file's `text` option is
  # types.lines, so a second definition is *concatenated* rather than replacing
  # it, which is how the deployed file ended up with two [Settings] groups.
  # Colours are noctalia's job — it writes gtk.css/noctalia.css next to this and
  # never touches settings.ini.
  gtk = {
    enable = true;

    # gtk-application-prefer-dark-theme on both, plus gtk-interface-color-scheme
    # on GTK4, instead of hand-writing the key per version.
    colorScheme = "dark";

    font = {
      name = "MiSans";
      size = 10;
    };

    theme.name = "Adwaita";
    # GTK4 takes its theme from libadwaita, not gtk-theme-name, so leave the key
    # out there rather than writing one nothing reads.
    gtk4.theme = null;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    # cursorTheme is deliberately not set here: home.pointerCursor in xdg.nix
    # already feeds gtk.cursorTheme (name, package and size) via mkDefault, and
    # is also what drives HYPRCURSOR_*/XCURSOR_*. Declaring the cursor twice is
    # how the two halves drift apart.
  };
}
