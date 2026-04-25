{pkgs, ...}: {
  # Styling Options
  stylix = {
    enable = true;
    fonts = {
      monospace = {
        package = pkgs.maple-mono.NF-CN;
        name = "Maple Mono NF CN";
      };
      sansSerif = {
        #package = pkgs.maple-mono.NF-CN;
        name = "MiSans";
      };
      serif = {
        #package = pkgs.maple-mono.NF-CN;
        name = "MiSans";
      };
      sizes = {
        applications = 12;
        terminal = 16;
        desktop = 12;
        popups = 12;
      };
    };
  };
}
