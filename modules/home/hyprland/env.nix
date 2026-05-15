{...}: let
  envPair = name: value: {_args = [name value];};
in {
  wayland.windowManager.hyprland.settings.env = [
    (envPair "NIXOS_OZONE_WL" "1")
    (envPair "NIXPKGS_ALLOW_UNFREE" "1")
    (envPair "XDG_CURRENT_DESKTOP" "Hyprland")
    (envPair "XDG_SESSION_TYPE" "wayland")
    (envPair "XDG_SESSION_DESKTOP" "Hyprland")
    (envPair "GDK_BACKEND" "wayland,x11")
    (envPair "CLUTTER_BACKEND" "wayland")
    (envPair "QT_QPA_PLATFORM" "wayland;xcb")
    (envPair "QT_WAYLAND_DISABLE_WINDOWDECORATION" "1")
    (envPair "QT_AUTO_SCREEN_SCALE_FACTOR" "1")
    (envPair "SDL_VIDEODRIVER" "x11")
    (envPair "MOZ_ENABLE_WAYLAND" "1")
    # This is to make electron apps start in wayland
    (envPair "ELECTRON_OZONE_PLATFORM_HINT" "wayland")
    (envPair "GDK_SCALE" "1.5")
    (envPair "QT_SCALE_FACTOR" "1.5")
    (envPair "EDITOR" "nvim")
    (envPair "TERMINAL" "wezterm")
    (envPair "XDG_TERMINAL_EMULATOR" "wezterm")
    (envPair "HYPRCURSOR_THEME" "Bibata-Modern-Ice")
    (envPair "HYPRCURSOR_SIZE" "24")
    (envPair "XCURSOR_THEME" "Bibata-Modern-Ice")
    (envPair "XCURSOR_SIZE" "24")
  ];
}
