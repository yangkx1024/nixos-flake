{
  pkgs,
  config,
  ...
}: let
  ghostHome = "${config.xdg.configHome}/ghostty";
  shaderFile = "${ghostHome}/shaders/shader.glsl";
in {
  # Install Ghostty theme(s) so referenced names resolve even if the package's share/themes doesn't include them
  home.file = {
    "${shaderFile}".source = pkgs.fetchurl {
      # enabling custom-shader-animation = always, as cursors
      # can get stuck on losing focus and look terrible. this
      # will only animate for half a second, if you change to
      # a whole-terminal crazily animated thing then probably
      # disable that option
      url = "https://github.com/sahaj-b/ghostty-cursor-shaders/raw/88c27a55b2e970eec19c21ef858a1a5bea489a1d/cursor_warp.glsl";
      sha256 = "sha256-9ZlLcNu5cH0Ibc7qrS+lfrY4neesQm/5FdTCNa85G+s=";
    };
  };

  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;
    enableZshIntegration = true;
    enableBashIntegration = true;
    clearDefaultKeybinds = true;
    settings = {
      custom-shader = shaderFile;
      theme = "noctalia"
      custom-shader-animation = "always";
      confirm-close-surface = "false";
      font-family = "Maple Mono NF CN";
      font-size = 14;
      adjust-cell-height = "10%";
      window-theme = "dark";
      window-height = "32";
      window-width = "110";
      background-opacity = "1.00";
      background-blur-radius = "60";
      selection-background = "#2d3f76";
      selection-foreground = "#c8d3f5";
      cursor-style = "bar";
      mouse-hide-while-typing = "true";
      wait-after-command = "false";
      shell-integration = "detect";
      window-save-state = "always";
      gtk-single-instance = "true";
      unfocused-split-opacity = "0.5";
      quick-terminal-position = "center";
      shell-integration-features = "cursor,sudo,ssh-env,ssh-terminfo";
      bold-is-bright = "false";
      focus-follows-mouse = "true";
      # never show the size popups
      resize-overlay = "never";
      keybind = [
        # Copy/Paste
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"

        # Font size control
        "ctrl+shift+plus=increase_font_size:1"
        "ctrl+shift+minus=decrease_font_size:1"
        "ctrl+shift+zero=reset_font_size"
      ];
    };
  };
}
