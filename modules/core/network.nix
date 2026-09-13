{
  pkgs,
  host,
  vars,
  options,
  ...
}: {
  networking = {
    hostName = "${host}";
    inherit (vars) hostId;
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
