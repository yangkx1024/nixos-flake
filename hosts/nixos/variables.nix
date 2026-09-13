{
  gitUsername = "Kexuan Yang";
  gitEmail = "kexuan.yang@gmail.com";

  browser = "google-chrome-stable";
  terminal = "ghostty";
  extraMonitorSettings = ''hl.monitor({ output = "DP-1", mode = "highres", position = "auto", scale = "2", bitdepth = 10 })'';

  # GPU PCI bus IDs. Only the hybrid profiles read these
  # (profiles/nvidia-laptop, profiles/amd-nvidia-hybrid); find yours with
  # `lspci | grep -E "VGA|3D"`. Left commented out because this host is a
  # single-GPU AMD desktop — those profiles then fall back to the defaults in
  # modules/drivers/ instead of failing to evaluate.
  # intelID = "PCI:1:0:0";
  # amdgpuID = "PCI:5:0:0";
  # nvidiaID = "PCI:0:2:0";

  # Set network hostId if required (needed for zfs)
  # Otherwise leave as-is
  hostId = "5ab03f50";
}
