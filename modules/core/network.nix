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
    # glibc's default (5s x 2 attempts x 2 MagicDNS servers) holds a hung lookup
    # for up to 20s while the uplink is down after resume; cap it at ~4s.
    resolvconf.extraOptions = ["timeout:2" "attempts:1"];
  };

  # nsncd serves every NSS lookup from one pool of 8 workers with no queue. After
  # resume, hosts lookups stalled on DNS fill it, so even getpwnam for a local
  # user (lock screen PAM) waits until nsncd times out and restarts.
  # See twosigma/nsncd#158; nixpkgs#422695 would turn this into an option.
  systemd.services.nscd.environment.NSNCD_WORKER_COUNT = "32";

  environment.systemPackages = with pkgs; [networkmanagerapplet];
}
