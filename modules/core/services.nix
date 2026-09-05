{profile, ...}: {
  # Services to start
  services = {
    fwupd.enable = true;
    upower.enable = true; # noctalia shell battery
    libinput.enable = true; # Input Handling
    fstrim.enable = true; # SSD Optimizer
    gvfs.enable = true; # For Mounting USB & More
    power-profiles-daemon.enable = true;
    openssh = {
      enable = true; # Enable SSH
      settings = {
        PermitRootLogin = "no"; # Prevent root from SSH login
        PasswordAuthentication = true; #Users can SSH using kb and password
        KbdInteractiveAuthentication = true;
      };
      ports = [22];
    };
    blueman.enable = true; # Bluetooth Support
    tumbler.enable = true; # Image/video preview
    gnome.gnome-keyring.enable = true;

    smartd = {
      enable =
        if profile == "vm"
        then false
        else true;
      autodetect = true;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig.pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 256;
          "default.clock.min-quantum" = 256;
          "default.clock.max-quantum" = 256;
        };
      };
      extraConfig.pipewire-pulse."92-low-latency" = {
        context.modules = [
          {
            name = "libpipewire-module-protocol-pulse";
            args = {
              pulse.min.req = "256/48000";
              pulse.default.req = "256/48000";
              pulse.max.req = "256/48000";
              pulse.min.quantum = "256/48000";
              pulse.max.quantum = "256/48000";
            };
          }
        ];
      };
    };
    keyd = {
      enable = true;
      keyboards = {
        default = {
          ids = [
            "*"
            "-514b:4d03"
          ];
          settings = {
            main = {
              capslock = "layer(control)";
            };
          };
        };
        qk65-mk3 = {
          ids = ["k:514b:4d03"];
          settings = {
            global = {
              # Firmware-generated chords arrive within the same USB frame.
              chord_timeout = 5;
            };
            main = {
              capslock = "layer(control)";

              brightnessdown = "f1";
              brightnessup = "f2";
              "leftcontrol+up" = "f3";
              "leftmeta+space" = "f4";
              voicecommand = "f5";
              "leftshift+leftmeta+4" = "f6";
              previoussong = "f7";
              playpause = "f8";
              nextsong = "f9";
              mute = "f10";
              volumedown = "f11";
              volumeup = "f12";
            };
          };
        };
      };
    };
  };
}
