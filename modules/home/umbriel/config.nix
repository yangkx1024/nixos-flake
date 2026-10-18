{
  vars,
  config,
  ...
}: let
  cursor = config.home.pointerCursor;
in {
  programs.umbriel.settings = {
    # Written by noctalia's umbriel template: border, overview and scratchpad
    # colors. The main file is applied after its includes, so it would win
    # over noctalia.toml on any key both set. config.toml is a store symlink;
    # this serializes exactly as assets/templates/umbriel/apply.sh would
    # write it, so the hook finds nothing to change and never tries to
    # replace the file. default.nix checks that at build time.
    include.optional.files = ["noctalia.toml"];

    general = {
      autostart = ["noctalia"];
      show_cheatsheet = false;
    };

    input = {
      keyboard = {
        options = "grp:alt_caps_toggle,caps:super";
        repeat_delay = 300;
        numlock_toggle = true;
      };
      touchpad = {
        natural_scroll = true;
        scroll_factor = 0.5;
        click_method = "clickfinger";
      };
      # Like niri's focus-follows-mouse max-scroll-amount="0%": crossing a
      # partly visible column doesn't scroll the view to it.
      focus = {
        follows_mouse = true;
        follows_mouse_max_scroll = 0.0;
      };
      cursor = {
        theme = cursor.name;
        inherit (cursor) size;
      };
    };

    layout = {
      extent_presets = [0.33333 0.5 0.66667 0.95];
      # Hyprland's scrolling layout ran at column_width = 0.95.
      scrolling.default_extent_fraction = 0.95;
    };

    # Umbriel's packaged config has this; built in, every corner is off. The
    # delay keeps it from firing on the way to the bar's workspace pill.
    hot_corners.top_left = {
      enabled = true;
      delay_ms = 200;
      action = "overview-open";
    };

    output = vars.umbrielOutputSettings or {};
  };
}
