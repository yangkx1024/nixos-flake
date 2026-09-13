{
  osConfig,
  profile,
  ...
}: {
  # Shell config shared by every shell home-manager manages.
  # home.shellAliases feeds programs.{bash,zsh}.shellAliases; anything genuinely
  # shell-specific goes in that shell's own module instead.
  home.shellAliases = {
    ".." = "cd ..";
    c = "clear";
    fr = "nh os switch --hostname ${profile}";
    fu = "nh os switch --hostname ${profile} --update";
    gd = "git diff";
    gst = "git status";
    man = "batman";
    # On-demand run of the same retention policy as the weekly nh-clean timer
    # (modules/core/nh.nix), then drop boot entries for deleted generations,
    # which nh clean does not do.
    ncg = "nh clean all ${osConfig.programs.nh.clean.extraArgs} && sudo /run/current-system/bin/switch-to-configuration boot";
    nix-fmt-all = "nix fmt ./";
    sv = "sudo nvim";
    v = "nvim";
    vim = "nvim";
    zed = "zeditor";
  };

  # Prepended to PATH, in this order.
  home.sessionPath = [
    "$HOME/.local/bin" # `uv tool` links its executables here
    "/usr/local/bin"
  ];
}
