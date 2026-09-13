{
  config,
  pkgs,
  host,
  vars,
  options,
  ...
}: {
  services.tailscale = {
    enable = true; # also installs the tailscale CLI
    openFirewall = true; # 41641/udp, lets peers connect directly instead of via DERP
  };

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
      trustedInterfaces = [config.services.tailscale.interfaceName];
      # sshd opens its own port via services.openssh.openFirewall
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
  };

  environment.systemPackages = with pkgs; [networkmanagerapplet];
}
