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
  # Enable GPU Drivers
  drivers.amdgpu.enable = false;
  drivers.nvidia.enable = true;
  drivers.nvidia-prime = {
    enable = true;
    # Bus IDs come from the host's variables.nix when it declares them; a host
    # that doesn't (this one is a single-GPU desktop) falls through to the
    # defaults in modules/drivers/nvidia-prime-drivers.nix rather than failing
    # to evaluate. mkIf's value is lazy, so the missing attribute is never
    # forced. Get the real IDs from `lspci | grep -E "VGA|3D"`.
    intelBusID = lib.mkIf (vars ? intelID) vars.intelID;
    nvidiaBusID = lib.mkIf (vars ? nvidiaID) vars.nvidiaID;
  };
  drivers.intel.enable = false;
  vm.guest-services.enable = false;
}
