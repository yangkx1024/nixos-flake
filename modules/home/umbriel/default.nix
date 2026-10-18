{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.umbriel;
in {
  imports = [
    inputs.umbriel.homeModules.default
    ./binds.nix
    ./config.nix
    ./rules.nix
  ];

  # settings is an attrset merged from the files above. The package is the
  # flake's default; the NixOS module installs the same one.
  programs.umbriel.enable = true;

  # The flake dropped build-time validation, and at startup any config error
  # makes Umbriel fall back to its default config. `config validate` fails on
  # any warning, including unknown actions and bad regexes. Then noctalia's
  # umbriel hook runs on a copy: if it would change anything, it would try to
  # write through the store symlink on every theme change.
  home.extraDependencies = let
    configFile = config.xdg.configFile."umbriel/config.toml".source;
  in [
    (pkgs.runCommandLocal "umbriel-config-check" {} ''
      ${lib.getExe cfg.package} config validate -c ${configFile}
      mkdir -p home/umbriel
      install -m 644 ${configFile} home/umbriel/config.toml
      XDG_CONFIG_HOME=$PWD/home ${pkgs.bash}/bin/bash \
        ${config.programs.noctalia.package}/share/noctalia/assets/templates/umbriel/apply.sh
      cmp ${configFile} home/umbriel/config.toml
      touch $out
    '')
  ];
}
