{username, ...}: {
  boot.supportedFilesystems = ["nfs"];

  systemd.mounts = [
    {
      type = "nfs";
      mountConfig = {
        # retry=0 + a short TimeoutSec: fail fast instead of blocking for the
        # default 90s when the NAS is offline, so `ls`/Thunar return an error
        # rather than appearing hung.
        Options = "noatime,retry=0";
        TimeoutSec = "10s";
      };
      what = "192.168.1.9:/mnt/hdd/shared";
      where = "/home/${username}/nas";
    }
  ];
  systemd.automounts = [
    {
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/home/${username}/nas";
    }
  ];
}
