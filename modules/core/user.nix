{
  config,
  lib,
  pkgs,
  inputs,
  username,
  host,
  profile,
  ...
}: let
  inherit (import ../../hosts/${host}/variables.nix) gitUsername;
in {
  imports = [inputs.home-manager.nixosModules.home-manager];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs username host profile;};
    users.${username} = {
      imports = [./../home];
      home = {
        username = "${username}";
        homeDirectory = "/home/${username}";
        stateVersion = "26.05";
      };
    };
  };
  users.mutableUsers = true;
  users.users.${username} = {
    isNormalUser = true;
    description = "${gitUsername}";
    # No adbusers: programs.adb is gone, systemd >= 258 grants adb/fastboot
    # devices to the seat user via uaccess.
    extraGroups =
      [
        "i2c" # DDC/CI monitor control
        "libvirtd" # Virt manager/QEMU access
        "lp" # Printer access
        "networkmanager"
        "scanner"
        "wheel" # Access sudo
      ]
      # Access to docker as non-root; the group only exists when docker is enabled
      ++ lib.optional config.virtualisation.docker.enable "docker";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB9+FrsApB3pPYWu0hiFoPSup+F9g7WxQNQonYqyQmrs kexuan.yang@yangkx.net"
    ];
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
  };
  environment.shells = [pkgs.zsh];
  nix.settings.allowed-users = ["${username}"];
}
