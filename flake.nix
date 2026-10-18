{
  description = "Kexuan's NixOS";
  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # beta branch: only moves on beta releases, not the daily twilight bumps.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # Source only: built by nixpkgs' hyprlandPlugins.hyprspace against
    # pkgs.hyprland, so the plugin ABI always matches the running compositor.
    hyprspace = {
      url = "github:KZDKM/Hyprspace";
      flake = false;
    };

    # Main branch rather than nixpkgs' snapshot while Umbriel is young. Built
    # locally against this nixpkgs (no binary cache), as is its portal.
    umbriel = {
      url = "github:noctalia-dev/umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=latest";

    openlogi.url = "github:yangkx1024/OpenLogi/nix-cachix";

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

    msime = {
      url = "github:yangkx1024/msime/nix-cachix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Native GPUI client for the herdr daemon. Upstream publishes no binary
    # cache, so this builds from source; following our nixpkgs links it
    # against the same mesa/vulkan-loader/wayland as the rest of the desktop.
    herdr-gpui = {
      url = "github:penso/herdr-gpui";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    usbeehive = {
      url = "github:yangkx1024/usbeehive/nix";
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
    # Host settings, passed to every NixOS and home-manager module as `vars`.
    vars = import ./hosts/${host}/variables.nix;

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
          inherit vars;
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
