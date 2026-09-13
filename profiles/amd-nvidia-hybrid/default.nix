{
  host,
  lib,
  vars,
  ...
}: {
  imports = [
    ../../hosts/${host}
    ../../modules/drivers
    ../../modules/core
  ];

  # Enable AMD+NVIDIA hybrid drivers (Prime offload with AMD as primary)
  drivers.nvidia-amd-hybrid = {
    enable = true;
    # See the note in profiles/nvidia-laptop: optional so hosts without these
    # variables still evaluate, defaults live in
    # modules/drivers/nvidia-amd-hybrid.nix.
    amdgpuBusId = lib.mkIf (vars ? amdgpuID) vars.amdgpuID;
    nvidiaBusId = lib.mkIf (vars ? nvidiaID) vars.nvidiaID;
  };

  # Ensure other driver toggles are off for this profile
  drivers.amdgpu.enable = false;
  drivers.nvidia.enable = false;
  drivers.nvidia-prime.enable = false;
  drivers.intel.enable = false;

  vm.guest-services.enable = false;
}
