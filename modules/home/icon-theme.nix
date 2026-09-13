{
  config,
  lib,
  pkgs,
  ...
}: let
  # Papirus-Dark / Papirus-Light, rendered by noctalia per mode. Not plain
  # Papirus for light: it pairs dark app icons with light panel/tray icons,
  # which wash out on noctalia's light bar.
  iconTheme = "Papirus-{{ mode | pascal_case }}";

  applyIconTheme = pkgs.writeShellApplication {
    name = "noctalia-icon-theme";
    runtimeInputs = [pkgs.coreutils pkgs.dconf];
    text = ''
      icons=$1 qtct_dir=$2

      # GTK3, GTK4 (via the portal) and noctalia's own launcher/tray icons all
      # resolve through this key. Skip no-op writes: every write makes running
      # GTK apps reload their icons.
      key=/org/gnome/desktop/interface/icon-theme
      if [ "$(dconf read "$key")" != "'$icons'" ]; then
        dconf write "$key" "'$icons'"
      fi

      # noctalia rewrites the conf in place, but qt5ct/qt6ct only watch their
      # directory for added/removed entries, so make one to reload running apps.
      touch "$qtct_dir/.reload"
      rm -f "$qtct_dir/.reload"
    '';
  };
in {
  # The icon theme follows noctalia's light/dark mode, so noctalia owns it, not
  # Home Manager (gtk.nix explains why gtk.iconTheme stays unset). qt5ct/qt6ct
  # read icon_theme from their one config file, so that file is a noctalia user
  # template rather than a fixed xdg.configFile. Templates render at startup and
  # on every mode switch, and post_hook gets the same {{ mode }}.
  programs.noctalia.settings.theme.templates.user =
    lib.mapAttrs (qtct: fonts: let
      dir = "${config.xdg.configHome}/${qtct}";
    in {
      input_path = "${pkgs.writeText "${qtct}.conf" ''
        [Appearance]
        color_scheme_path=${dir}/colors/noctalia.conf
        custom_palette=true
        icon_theme=${iconTheme}

        [Fonts]
        ${fonts}''}";
      output_path = "${dir}/${qtct}.conf";
      post_hook = "${lib.getExe applyIconTheme} ${iconTheme} ${dir}";
      # Both entries drive the same dconf key; don't let them overlap.
      hook_async = false;
    }) {
      # The two tools serialise fonts differently.
      qt5ct = ''
        fixed="Maple Mono NF CN,10,-1,5,50,0,0,0,0,0,Regular"
        general="MiSans,10,-1,5,50,0,0,0,0,0"
      '';
      qt6ct = ''
        fixed="Maple Mono NF CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
        general="MiSans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
      '';
    };
}
