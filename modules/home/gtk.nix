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

  # noctalia's gtk hook only switches to adw-gtk3/adw-gtk3-dark when installed.
  home.packages = [pkgs.adw-gtk3];

  gtk = {
    enable = true;

    font = {
      name = "MiSans";
      size = 10;
    };

    # colorScheme, theme and iconTheme are deliberately not set: they follow
    # noctalia's light/dark mode, which sets color-scheme, gtk-theme (GTK3 has
    # no colour-scheme of its own) and, via icon-theme.nix, icon-theme in dconf.
    # HM would reload fixed values into dconf on every switch, and colorScheme
    # also writes gtk-application-prefer-dark-theme, which GTK3 always obeys.

    # cursorTheme is deliberately not set here: home.pointerCursor in xdg.nix
    # already feeds gtk.cursorTheme (name, package and size) via mkDefault, and
    # is also what drives HYPRCURSOR_*/XCURSOR_*. Declaring the cursor twice is
    # how the two halves drift apart.
  };
}
