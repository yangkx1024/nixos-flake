{
  config,
  lib,
  pkgs,
  ...
}: let
  # Rendered by noctalia's community "bat" template (modules/home/noctalia.nix).
  themeFile = "${config.xdg.configHome}/bat/themes/noctalia.tmTheme";
in {
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      # other styles available and cane be combined
      #  style = "numbers,changes,headers,rule,grid";
      style = "full";
      theme = "noctalia";
    };
    extraPackages = with pkgs.bat-extras; [
      batman
      batpipe
      batgrep
    ];
  };
  home.sessionVariables = {
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
  };

  # bat only sees themes that are compiled into its cache, so every palette
  # change needs a `bat cache --build`. The template's own post_hook would do
  # that, but it first touches bat/config, which is a read-only store symlink
  # here, and dies before reaching the rebuild. Watch the rendered theme instead.
  systemd.user.paths.bat-noctalia-theme = {
    Unit.Description = "Watch noctalia's bat theme";
    Path.PathChanged = themeFile;
    Install.WantedBy = ["default.target"];
  };
  systemd.user.services.bat-noctalia-theme = {
    Unit.Description = "Rebuild bat cache after noctalia renders its theme";
    Service = {
      Type = "oneshot";
      # Same workaround as home-manager's batCache activation:
      # https://github.com/sharkdp/bat/issues/1726
      WorkingDirectory = "${pkgs.emptyDirectory}";
      ExecStart = "${lib.getExe config.programs.bat.package} cache --build";
    };
  };
}
