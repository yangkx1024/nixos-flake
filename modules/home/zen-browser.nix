{inputs, ...}: {
  imports = [inputs.zen-browser.homeModules.beta];

  programs.zen-browser = {
    enable = true;

    # Lands in the wrapper's mozilla.cfg (autoconfig, read at every launch).
    # defaultPref only moves the default, so a value changed in about:config
    # still wins and persists.
    extraPrefs = ''
      // Open window.open() popups (e.g. OIDC logins) as tabs: on
      // Hyprland they'd otherwise tile as full-size windows.
      defaultPref("browser.link.open_newwindow.restriction", 0);
      // No shortcuts row on the new tab page.
      defaultPref("browser.newtabpage.activity-stream.feeds.system.topsites", false);
    '';

    # Extensions by AMO id -> slug, installed from AMO's latest release and
    # kept updated by Zen itself. normal_installed still allows disabling them
    # in the UI, but not removing them. Dropping an entry here doesn't
    # uninstall the extension, it only makes it removable in the UI again.
    policies.ExtensionSettings =
      builtins.mapAttrs (_: slug: {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
        installation_mode = "normal_installed";
      }) {
        "uBlock0@raymondhill.net" = "ublock-origin";
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "bitwarden-password-manager";
        "jid0-GjwrPchS3Ugt7xydvqVK4DQk8Ls@jetpack" = "gmail-notifier-restartless";
      };

    # The default profile, link to ~/.config/zen. Only
    # profiles.ini is generated from this; nothing declares pins, spaces or
    # pinsForce, so zen-sessions.jsonlz4 is never touched and tabs pinned in
    # the UI stay UI-managed.
    profiles.default = {
      id = 0;
      name = "Default Profile";
      path = "default";
      isDefault = true;
    };
  };
}
