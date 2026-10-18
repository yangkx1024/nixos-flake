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
    # Rendered by noctalia's kitty template. Its post_hook, which would add
    # this include and SIGUSR1 kitty, dies touching the read-only kitty.conf
    # symlink; harmless, since the include is here and kitty's
    # auto_reload_config (on by default) picks up the new theme file.
    extraConfig = ''
      include themes/noctalia.conf
    '';
  };
}
