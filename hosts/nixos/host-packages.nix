{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    #  Add local pacakaged here
    zed-editor
    gnome-disk-utility
    google-chrome
    loupe
    wirelesstools
    efibootmgr
    nwg-look
    mission-center
    papers
    #foliate
    remmina
    claude-code
  ];
  # Add host specific flatpaks here
  services = {
    flatpak = {
      packages = [
      ];
    };
  };
}
