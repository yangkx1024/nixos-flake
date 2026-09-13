{
  pkgs,
  host,
  options,
  ...
}: let
  inherit (import ../../hosts/${host}/variables.nix) hostId;
in {
  networking = {
    hostName = "${host}";
    hostId = hostId;
    networkmanager.enable = true;
    timeServers =
      options.networking.timeServers.default
      ++ [
        "sg.pool.ntp.org"
        "pool.ntp.org"
      ];
    firewall = {
      enable = true;
      # sshd opens its own port via services.openssh.openFirewall
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
  };

  environment.systemPackages = with pkgs; [networkmanagerapplet];
}
