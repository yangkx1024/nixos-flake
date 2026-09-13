{osConfig, ...}: {
  # Official tray app (`tailscale systray`), run as a user unit on
  # graphical-session.target. It re-registers with the StatusNotifierWatcher
  # whenever one appears, so starting before noctalia's tray is fine.
  # Toggling the connection or exit nodes needs this user to be the tailscaled
  # operator: `sudo tailscale set --operator=$USER` (persisted by tailscaled).
  services.tailscale-systray = {
    inherit (osConfig.services.tailscale) enable package;
  };
}
