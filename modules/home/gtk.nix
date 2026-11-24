{
  config,
  pkgs,
  ...
}: let
  # Rendered by noctalia's gtk3 template on every light/dark switch.
  gtk3Colors = "${config.xdg.configHome}/gtk-3.0/noctalia.css";
  gtk3Reload = "${config.xdg.configHome}/gtk-3.0/colors.css";
in {
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
  home.packages = [
    pkgs.adw-gtk3
    (pkgs.callPackage ../../pkgs/gtk3-colorreload.nix {})
  ];

  gtk = {
    enable = true;

    font = {
      name = "Noto Sans";
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

  # GTK3 reads the user gtk.css (and so noctalia.css) once per process
  # (settings_init_style in gtk/gtksettings.c), so a running app keeps the old
  # palette after a mode switch even though gtk-theme itself changes live.
  # colorreload-gtk-module (kde-gtk-config, loaded through GTK_MODULES in
  # session-env.nix: GTK3 on Wayland ignores gtk-modules from settings.ini)
  # watches gtk-3.0/colors.css and loads it into every running GTK3 app above
  # the user gtk.css. It only reacts to
  # writes to colors.css itself, not to files it imports, so copy noctalia's
  # palette there each time noctalia rewrites it. New processes still get the
  # colours through gtk.css; the module does not read colors.css at startup.
  systemd.user.paths.gtk3-noctalia-colors-reload = {
    Unit.Description = "Watch noctalia's GTK3 colours";
    Path.PathChanged = gtk3Colors;
    Install.WantedBy = ["default.target"];
  };
  systemd.user.services.gtk3-noctalia-colors-reload = {
    Unit.Description = "Live-reload noctalia's GTK3 colours in running GTK3 apps";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/cp ${gtk3Colors} ${gtk3Reload}";
    };
  };
}
