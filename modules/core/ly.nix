{
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "matrix";
      bigclock = true;
      # --- Color Settings (0xAARRGGBB) ---
      # Background color
      bg = "0x00131410";
      # Foreground text color
      fg = "0x00e4e2dc";
      border_fg = "0x00c3c9b0";
      error_fg = "0x00ffb4ab";
      # Clock color
      clock_color = "#e4e2dc";
      # Set bigclock to show the seconds.
      bigclock_seconds = true;
      # Title to show at the top of the main box
      # If set to null, none will be shown
      box_title = "Hello World!";
      session_log = null;
    };
  };
}
