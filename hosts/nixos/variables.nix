{
  gitUsername = "Kexuan Yang";
  gitEmail = "kexuan.yang@gmail.com";

  browser = "google-chrome-stable";
  terminal = "ghostty";
  extraMonitorSettings = ''hl.monitor({ output = "DP-1", mode = "highres", position = "auto", scale = "2", bitdepth = 10 })'';

  # Set network hostId if required (needed for zfs)
  # Otherwise leave as-is
  hostId = "5ab03f50";
}
