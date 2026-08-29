{
  pkgs,
  username,
  ...
}: {
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 3";
    };
    flake = "/home/${username}/flake";
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor
    nvd
  ];
}
