# Kexuan's NixOS Flake

Personal NixOS + Home Manager configuration. Hyprland desktop, multiple GPU profiles, Noctalia shell.
Inspired by [ZaneyOS](https://gitlab.com/Zaney/zaneyos), I simplified the configurations I didn't need.

## Preview

<video src="recording/recording_20260428_100130_compressed.mp4" controls width="720"></video>

If your viewer does not embed the video inline, open
[`recording/recording_20260428_100130_compressed.mp4`](recording/recording_20260428_100130_compressed.mp4) directly.

## Structure

```
.
├── flake.nix              # Inputs + nixosConfigurations (one per GPU profile)
├── flake.lock
├── hosts/
│   └── nixos/             # Per-host: hardware.nix + variables.nix (browser, terminal, monitor, hostId)
├── profiles/              # GPU profiles — each toggles drivers and imports core/home modules
│   ├── amd/
│   └── vm/
├── modules/
│   ├── core/              # System-level modules (boot, network, fonts, packages, services, ...)
│   ├── drivers/           # GPU driver modules (amd, nvidia, nvidia-prime, hybrid, intel, vm)
│   └── home/              # Home Manager modules (hyprland, terminals, fastfetch, noctalia, ...)
├── fonts/                 # Bundled fonts
├── wallpapers/
└── recording/             # Demo recordings
```

`flake.nix` exposes six `nixosConfigurations` built from a single `mkNixosConfig` helper:
`amd`, `nvidia`, `nvidia-laptop`, `amd-nvidia-hybrid`, `intel`, `vm`. Each one imports the
matching `profiles/<name>` directory, which in turn pulls in `modules/core`, `modules/drivers`,
and the host config under `hosts/<host>`.

User-level configuration is delivered through Home Manager, wired up in
`modules/core/user.nix` and rooted at `modules/home/default.nix`.

## Configure

1. **Set host variables** — edit `hosts/nixos/variables.nix`:

   ```nix
   {
     gitUsername = "Your Name";
     gitEmail = "you@example.com";
     browser = "google-chrome-stable";
     terminal = "ghostty";
     extraMonitorSettings = "monitor = DP-1, highres, auto, auto, bitdepth, 10";
     hostId = "xxxxxxxx";   # required for ZFS
   }
   ```

2. **Generate hardware config** — replace `hosts/nixos/hardware.nix` with the output of
   `nixos-generate-config --show-hardware-config` for your machine.

3. **Pick a GPU profile** — `amd`, `nvidia`, `nvidia-laptop`, `amd-nvidia-hybrid`, `intel`, or `vm`.
   To add a new profile, drop a `profiles/<name>/default.nix` that imports the host and toggles
   the driver flags in `modules/drivers/`.

4. **Adjust user / hostname** — defaults live at the top of `flake.nix`:

   ```nix
   host = "nixos";
   username = "yangkx";
   ```

5. **Toggle modules** — add or remove entries in `modules/core/default.nix` and
   `modules/home/default.nix` to enable/disable system or home features.

## Build & switch

```sh
# Rebuild and switch using the AMD profile
sudo nixos-rebuild switch --flake .#amd

# Other profiles
sudo nixos-rebuild switch --flake .#nvidia
sudo nixos-rebuild switch --flake .#vm

# Format Nix files
nix fmt
```

`nh` is enabled in `modules/core/nh.nix`, so `nh os switch .` also works.

## Note

I disabled `hypridle` and `hyprlock`, as I prefer using the Noctalia shell's idle management and lock screens.
If you find there is no idle management after you install this flake, go Noctalia shell settings and enable it.
