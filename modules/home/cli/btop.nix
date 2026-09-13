{pkgs, ...}: {
  programs.btop = {
    enable = true;
    package = pkgs.btop.override {
      rocmSupport = true;
      cudaSupport = true;
    };
    settings = {
      # Rendered to btop/themes/noctalia.theme by noctalia's builtin template.
      # Its apply hook can't write btop.conf (a store symlink), but once this is
      # set it skips the write and just signals running btops to reload.
      color_theme = "noctalia";
      vim_keys = true;
      rounded_corners = true;
      proc_tree = true;
      show_gpu_info = "on";
      show_uptime = true;
      show_coretemp = true;
      cpu_sensor = "auto";
      show_disks = true;
      only_physical = true;
      io_mode = true;
      io_graph_combined = false;
    };
  };
}
