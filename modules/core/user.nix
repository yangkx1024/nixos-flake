{
  config,
  lib,
  pkgs,
  inputs,
  username,
  host,
  profile,
  vars,
  ...
}: let
  inherit (vars) gitUsername;
  accountsDir = "/var/lib/AccountsService";
  accountIcon = "${accountsDir}/icons/${username}";
in {
  imports = [inputs.home-manager.nixosModules.home-manager];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs username host profile vars;};
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

  # Account avatar, read by greeters from the AccountsService IconFile. Without
  # an Icon key it falls back to ~/.face, which other users can't read through
  # the 0700 home, and Noctalia's declarative shell.avatar_path never calls
  # SetIconFile. Icon= stays a fixed path so the keyfile never changes
  # (accounts-daemon only rereads it on restart or user reload); a new face.jpg
  # just retargets the symlink.
  systemd.tmpfiles.settings."10-accountsservice-icon" = lib.mkIf config.services.accounts-daemon.enable {
    ${accountIcon}."L+".argument = "${../home/hyprland/face.jpg}";
    # Owns the whole keyfile: accounts-daemon rewrites the full [User] group
    # anyway, and this user has no other keys set (checked over D-Bus).
    "${accountsDir}/users/${username}"."f+" = {
      mode = "0600";
      argument = ''
        [User]
        Icon=${accountIcon}
        SystemAccount=false
      '';
    };
  };
  environment.shells = [pkgs.zsh];
  nix.settings.allowed-users = ["${username}"];
}
