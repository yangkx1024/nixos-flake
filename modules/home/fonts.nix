{
  lib,
  osConfig,
  ...
}: {
  # Flatpak sandboxes only see ~/.config/fontconfig, not /etc/fonts, so the
  # system default-font aliases have to exist at the user level too.
  fonts.fontconfig.defaultFonts = osConfig.fonts.fontconfig.defaultFonts;

  # Flatpak reads overrides only from the app's own installation; the system
  # global override doesn't reach user-installed apps.
  home.file.".local/share/flatpak/overrides/global".text = ''
    [Context]
    filesystems=${lib.concatStringsSep ";" osConfig.services.flatpak.overrides.settings.global.Context.filesystems}
  '';
}
