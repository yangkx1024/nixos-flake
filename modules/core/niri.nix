{...}: {
  # Trial session next to Hyprland; noctalia-greeter's session picker lists
  # both and remembers the last one. nixpkgs' build, not niri-flake, for the
  # same glibc/Mesa reason Hyprland and noctalia come from nixpkgs.
  programs.niri = {
    enable = true;
    # Thunar is the file manager; the GTK portal's file chooser is enough.
    useNautilus = false;
  };
}
