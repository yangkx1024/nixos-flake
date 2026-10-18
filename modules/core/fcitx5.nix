{
  pkgs,
  inputs,
  ...
}: let
  # fcitx5-rime bakes RIME_DATA_DIR in at compile time and defaults it to
  # rime-data; override it to rime-ice (雾凇拼音) so the schemas and dictionaries
  # come from the store instead of being copied into ~/.local/share by hand.
  # This is a cache miss (~6s local build), but it is the API nixpkgs documents
  # for this, and it replaces rime-data rather than adding to it - shipping the
  # stock binary plus rime-ice would put both data sets in the closure.
  # The user-side patch that enables it lives in modules/home/fcitx5.nix.
  rimeWithIce = pkgs.fcitx5-rime.override {
    rimeDataPkgs = [pkgs.rime-ice];
  };
in {
  # msime: Fcitx5 addon, msime-linux-setup on PATH and the provider user units.
  imports = [inputs.msime.nixosModules.default];
  programs.msime.enable = true;

  # fcitx5-with-addons bundles fcitx5-configtool by default, and configtool's
  # KCM support drags libplasma and plasma-activities into the closure. It
  # cannot save here anyway (config files are store symlinks, see
  # modules/home/fcitx5.nix), so drop it. This has to be an overlay: the fcitx5
  # module builds its own copy of the package for QT_PLUGIN_PATH, so overriding
  # i18n.inputMethod.package alone leaves the configtool build in the closure.
  nixpkgs.overlays = [
    (final: prev: {
      qt6Packages = prev.qt6Packages.overrideScope (qfinal: qprev: {
        fcitx5-with-addons = qprev.fcitx5-with-addons.override {withConfigtool = false;};
      });
    })
  ];

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      rimeWithIce
    ];
  };
}
