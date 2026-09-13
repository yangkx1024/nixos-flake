{
  description = "Kexuan's NixOS";
  inputs.self.submodules = true;
  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=latest";

    hyprland.url = "github:hyprwm/Hyprland";

    noctalia.url = "github:noctalia-dev/noctalia";

    noctalia-greeter.url = "github:noctalia-dev/noctalia-greeter";

    openlogi.url = "github:yangkx1024/OpenLogi";

    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nix-flatpak,
    alejandra,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    host = "nixos";
    username = "yangkx";

    # One nixosConfiguration per GPU profile. gpuProfile names both the
    # profiles/ directory to import and the configuration itself, and is passed
    # through as the 'profile' specialArg so modules can branch on it
    # (modules/core/services.nix) and the fr/fu aliases rebuild the config they
    # were built from (modules/home/cli/shell.nix).
    mkNixosConfig = gpuProfile:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit host;
          profile = gpuProfile;
        };
        modules = [
          ./modules/core/overlays.nix
          ./profiles/${gpuProfile}
          nix-flatpak.nixosModules.nix-flatpak
        ];
      };
  in {
    nixosConfigurations = {
      amd = mkNixosConfig "amd";
      nvidia = mkNixosConfig "nvidia";
      nvidia-laptop = mkNixosConfig "nvidia-laptop";
      amd-nvidia-hybrid = mkNixosConfig "amd-nvidia-hybrid";
      intel = mkNixosConfig "intel";
      vm = mkNixosConfig "vm";
    };

    formatter.x86_64-linux = inputs.alejandra.packages.x86_64-linux.default;

    # `nix develop`; shell.nix stays usable on its own through `nix-shell`.
    devShells.x86_64-linux.default = import ./shell.nix {pkgs = nixpkgs.legacyPackages.x86_64-linux;};
  };
}
