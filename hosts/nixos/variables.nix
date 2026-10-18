{
  gitUsername = "Kexuan Yang";
  gitEmail = "kexuan.yang@gmail.com";

  browser = "zen-beta";
  terminal = "kitty";
  # Hyprland's view of the monitor; niriOutputSettings and
  # umbrielOutputSettings below are the same one for niri and Umbriel, so keep
  # the three in step.
  extraMonitorSettings = ''hl.monitor({ output = "DP-1", mode = "highres", position = "auto", scale = "2", bitdepth = 10 })'';
  # The same monitor for niri (modules/home/niri/config.nix), as KDL.
  niriOutputSettings = ''
    output "DP-1" {
        scale 2
        // Like Hyprland's vrr = 2: VRR only while a window with the
        // variable-refresh-rate rule (games) is on screen.
        variable-refresh-rate on-demand=true
    }
  '';
  # The same monitor for Umbriel (modules/home/umbriel/config.nix), as its
  # settings.output.
  umbrielOutputSettings."DP-1" = {
    scale = 2.0;
    bit_depth = 10;
    # Like Hyprland's vrr = 2: VRR only for fullscreen windows (games).
    vrr = "fullscreen";
  };

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
