{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.drivers.amdgpu;
in {
  options.drivers.amdgpu = {
    enable = mkEnableOption "Enable AMD Drivers";

    rocmHipSdk = mkEnableOption ''
      the /opt/rocm/hip compatibility symlink.

      Only software that dlopens the HIP runtime from the FHS path instead of
      the Nix store needs this - DaVinci Resolve, Blender's HIP backend, ROCm
      builds of PyTorch. It pulls rocmPackages.clr into the system closure at a
      cost of roughly 0.9 GiB, so it stays off until something actually asks for
      it. AMD graphics, Vulkan, OpenGL/Mesa and the rocm-smi that btop reads are
      all independent of it
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.xserver.videoDrivers = ["amdgpu"];
    }
    (mkIf cfg.rocmHipSdk {
      systemd.tmpfiles.rules = ["L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"];
    })
  ]);
}
