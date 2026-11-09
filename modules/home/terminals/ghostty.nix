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
      theme = "noctalia";
      # Animate only the focused surface. "always" keeps the loop running
      # unfocused too (so the cursor trail can't freeze mid-warp), but since
      # 1.4.0's GTK renderer rewrite it pins the iGPU at ~95% on 4K
      # (1.3.1 ran the same shader at ~16%).
      custom-shader-animation = "true";
      confirm-close-surface = "false";
      font-family = "Maple Mono NF CN";
      font-size = 12; # 12pt here == 16pt on macOS: Linux points are 96 DPI, macOS 72
      window-padding-x = 4;
      window-padding-y = 4;
      window-padding-balance = true;
      adjust-cell-height = "10%";
      window-theme = "system";
      window-height = "32";
      window-width = "110";
      background-opacity = "1.00";
      # copy selected text to both the selection and system clipboards
      copy-on-select = "clipboard";
      cursor-style = "bar";
      mouse-hide-while-typing = "true";
      wait-after-command = "false";
      shell-integration = "detect";
      window-save-state = "always";
      gtk-single-instance = "true";
      unfocused-split-opacity = "0.5";
      quick-terminal-position = "center";
      shell-integration-features = "cursor,sudo,ssh-env,ssh-terminfo";
      focus-follows-mouse = "true";
      # never show the size popups
      resize-overlay = "never";
      keybind = [
        # Copy/Paste
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
        "ctrl+shift+a=select_all"

        # Font size control
        "ctrl+shift+plus=increase_font_size:1"
        "ctrl+shift+minus=decrease_font_size:1"
        "ctrl+shift+zero=reset_font_size"
      ];
    };
  };
}
