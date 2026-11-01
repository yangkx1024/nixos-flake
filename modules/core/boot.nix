{
  pkgs,
  config,
  ...
}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    #kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
    kernelModules = ["v4l2loopback"];
    extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
    kernel.sysctl = {"vm.max_map_count" = 2147483642;};
    loader.systemd-boot.enable = true;
    loader.systemd-boot.consoleMode = "max";
    loader.efi.canTouchEfiVariables = true;
    # Skip the menu wait; hold Space during firmware handoff to get it back.
    loader.timeout = 0;
    # Appimage Support
    binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };
    plymouth.enable = true;
    plymouth.extraConfig = "UseSimpledrm=1";
    # Stage 1 is always systemd now (boot.initrd.verbose is gone); `quiet`
    # already hides systemd status, the udev params silence udev in both stages.
    kernelParams = ["quiet" "rd.udev.log_level=3" "udev.log_level=3"];
    consoleLogLevel = 0;
  };
}
