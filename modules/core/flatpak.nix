{
  pkgs,
  inputs,
  ...
}: {
  xdg.portal = {
    enable = true;
    extraPortals = [inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland];
    configPackages = [inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland];
  };
  services = {
    flatpak = {
      enable = true;

      # List the Flatpak applications you want to install
      # Use the official Flatpak application ID (e.g., from flathub.org)
      # Examples:
      packages = [
        "com.github.tchx84.Flatseal" #Manage flatpak permissions - should always have this
        "io.github.flattool.Warehouse"   # Manage flatpaks, clean data, remove flatpaks and deps
        # Add other Flatpak IDs here, e.g., "org.mozilla.firefox"
      ];

      # Update on a timer, not on activation: onActivation adds --or-update to
      # every run, and the unit re-runs on each switch, so rebuilds hit flathub.
      update = {
        onActivation = false;
        auto = {
          enable = true;
          onCalendar = "weekly";
        };
      };
    };
  };

  # The timer is Persistent, so a missed run fires at boot, usually before the
  # network is up; the failure would then retry every 60s until it is.
  systemd.services.flatpak-managed-install-timer = {
    wants = ["network-online.target"];
    after = ["network-online.target"];
  };
}
