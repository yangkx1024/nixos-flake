{pkgs, ...}: let
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
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      fcitx5-nord
      rimeWithIce
    ];
  };
}
