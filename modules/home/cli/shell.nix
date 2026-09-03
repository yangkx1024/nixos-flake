{profile, ...}: {
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
    ncg = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";
    nix-fmt-all = "nix fmt ./";
    sv = "sudo nvim";
    v = "nvim";
    zed = "zeditor";
  };

  # Prepended to PATH, in this order.
  home.sessionPath = [
    "$HOME/.local/bin" # `uv tool` links its executables here
    "/usr/local/bin"
  ];
}
