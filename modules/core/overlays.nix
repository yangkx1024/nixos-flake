{inputs, ...}: {
  nixpkgs.overlays = [
    # Provide package overlay here
    inputs.claude-code.overlays.default
    inputs.codex-cli-nix.overlays.default
    inputs.msime.overlays.default
    inputs.herdr-gpui.overlays.default
    # zen-browser-flake ships packages only, no overlay.
    # extraPrefs lands in the wrapper's mozilla.cfg (autoconfig, read at every
    # launch). defaultPref only moves the default, so a value changed in
    # about:config still wins and persists.
    (final: prev: {
      zen-browser = inputs.zen-browser.packages.${prev.stdenv.hostPlatform.system}.default.override {
        wrapFirefox = browser: args:
          prev.wrapFirefox browser (args
            // {
              extraPrefs = ''
                // Open window.open() popups (e.g. OIDC logins) as tabs: on
                // Hyprland they'd otherwise tile as full-size windows.
                defaultPref("browser.link.open_newwindow.restriction", 0);
                // No shortcuts row on the new tab page.
                defaultPref("browser.newtabpage.activity-stream.feeds.system.topsites", false);
              '';
            });
      };
    })
  ];
}
