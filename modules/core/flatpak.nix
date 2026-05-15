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
        #"com.github.tchx84.Flatseal" #Manage flatpak permissions - should always have this
        #"io.github.flattool.Warehouse"   # Manage flatpaks, clean data, remove flatpaks and deps
        # Add other Flatpak IDs here, e.g., "org.mozilla.firefox"
      ];

      # Optional: Automatically update Flatpaks when you run nixos-rebuild swit ch
      update.onActivation = true;
    };
  };
}
