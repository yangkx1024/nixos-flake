{
  pkgs,
  config,
  ...
}: {
  boot = {
    # 7.3.4-zen1 panics at boot: NULL deref in process_one_work (duplicated
    # `worker->current_at = worker->task->se.sum_exec_runtime` line in the zen
    # workqueue patch), hit as soon as xHCI probes. Fixed upstream in
    # zen-kernel d0c3b48 (https://github.com/zen-kernel/zen-kernel/issues/425);
    # switch back once nixpkgs ships a 7.3 zen newer than 7.3.4-zen1.
    #kernelPackages = pkgs.linuxPackages_zen;
    kernelPackages = pkgs.linuxPackages_latest;
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
    # bootvine (modules/core/bootvine.nix) draws the boot on tty12 instead;
    # Plymouth would fight it for the console.
    #plymouth.enable = true;
    #plymouth.extraConfig = "UseSimpledrm=1";
    # Stage 1 is always systemd now (boot.initrd.verbose is gone); `quiet`
    # already hides systemd status, the udev params silence udev in both stages.
    kernelParams = ["quiet" "rd.udev.log_level=3" "udev.log_level=3"];
    consoleLogLevel = 0;
  };
}
