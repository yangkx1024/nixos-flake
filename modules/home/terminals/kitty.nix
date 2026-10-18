{...}: {
  programs.kitty = {
    enable = true;
    font = {
      name = "Maple Mono NF CN";
      size = 12; # 12pt here == 16pt on macOS: Linux points are 96 DPI, macOS 72
    };
    settings = {
      window_padding_width = 4;
      modify_font = "cell_height 110%";
      confirm_os_window_close = 0;
      copy_on_select = "clipboard";
      cursor_shape = "beam";
      # Cursor jumps of 2+ cells, for cursors that sat still at least 3ms
      # (skips TUIs repainting), animate, drawn by the blaze shader.
      cursor_trail = 3;
      custom_shaders = "cursor-trail-blaze";
      # Fades rather than snaps: 0.5s out, 0.5s back.
      cursor_blink_interval = "0.5 ease-in-out";
      mouse_hide_wait = -1; # hide while typing
      enable_audio_bell = false;
      # The compositor draws borders and decorations.
      hide_window_decorations = true;
    };
    # Written by noctalia's kitty template. kitty.conf is a store symlink;
    # with the line already present, assets/templates/kitty/apply.sh finds
    # nothing to change and never writes through it.
    extraConfig = ''
      include themes/noctalia.conf
    '';
  };
}
