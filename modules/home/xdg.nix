{pkgs, ...}: {
  home.file = {
    "Pictures/Wallpapers/default.jpg".source = ../../wallpapers/default.jpg;
  };
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };
  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "image/jpeg" = ["org.gnome.Loupe.desktop"];
        "image/png" = ["org.gnome.Loupe.desktop"];
        "image/gif" = ["org.gnome.Loupe.desktop"];
        "image/webp" = ["org.gnome.Loupe.desktop"];
        "text/html" = ["google-chrome.desktop"];
        "x-scheme-handler/http" = ["google-chrome.desktop"];
        "x-scheme-handler/https" = ["google-chrome.desktop"];
        "x-scheme-handler/about" = ["google-chrome.desktop"];
        "application/pdf" = ["org.gnome.Papers.desktop"];
      };
    };
  };
}
