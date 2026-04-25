{username, ...}: {
  systemd.user.services.lazycat = {
    enable = true;
    description = "Lazycat service";
    after = ["network-online.target"];
    wantedBy = ["default.target"];
    serviceConfig = {
      ExecStart = "/home/${username}/hclient-cli-linux-amd64 --tun";
      Restart = "on-failure";
      RestartSec = "3";
      TimeoutStopSec = "90";
    };
  };
}
