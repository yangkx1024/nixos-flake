{
  services = {
    rpcbind.enable = true;
    nfs.server.enable = true;
  };
  systemd.mounts = [
    {
      type = "nfs";
      mountConfig = {
        Options = "noatime";
      };
      what = "192.168.1.9:/mnt/hdd/shared";
      where = "/home/yangkx/nas";
    }
  ];
  systemd.automounts = [
    {
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/home/yangkx/nas";
    }
  ];
}
