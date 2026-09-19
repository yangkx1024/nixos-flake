{
  inputs,
  pkgs,
  username,
  ...
}: {
  imports = [inputs.noctalia-greeter.nixosModules.default];

  services.displayManager.noctalia-greeter = {
    enable = true;
    # greeter-args left at default "" → session picker, remembers last choice.

    # Polkit rule letting this user run Noctalia's Greeter Sync without a
    # password. Scoped to `apply-appearance --sync` from the greeter package,
    # in an active local session.
    passwordless-sync-users = [username];

    # Sets settings.cursor.path to the package's share/icons. Non-empty settings
    # make greeter.toml a store symlink; session/scheme memory lives in sync.toml.
    cursorTheme.package = pkgs.bibata-cursors;
    settings.cursor = {
      theme = "Bibata-Modern-Ice";
      size = 24;
    };
  };
}
