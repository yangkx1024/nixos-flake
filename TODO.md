# Config review TODO

Review of this flake done 2026-09-12 against commit `d30b3ae` ("Add rime-ice"),
verified on the running system (Hyprland 0.56.0, nixpkgs `8ce4ef6`, HM master).

Work through these one at a time. Suggested order — behaviour first, then disk:
**1 → 2 → 3 → 5 → 6 → 11**, the rest opportunistically.

Each item records the symptom, the evidence it was verified with, and the intended
fix. Tick the box when done; keep the evidence line so a regression is recognisable.

---

## Broken (confirmed)

- [x] **1. Four of six `nixosConfigurations` don't evaluate** — `flake.nix:67-74` — **DONE 2026-09-12**

  `profiles/` only held `amd/` and `vm/`. `nvidia`, `nvidia-laptop`,
  `amd-nvidia-hybrid` and `intel` pointed at directories that didn't exist, so
  `nix flake check` failed with
  `error: path '.../profiles/nvidia' does not exist`.

  Resolution: added the four missing profiles, ported from `~/zaneyos/profiles`.

  Upstream zaneyos's `nvidia-laptop` and `amd-nvidia-hybrid` read `intelID` /
  `amdgpuID` / `nvidiaID` from `hosts/<host>/variables.nix`, and zaneyos's own
  `hosts/nixos/variables.nix` has those three lines commented out — a verbatim
  copy would have kept `nix flake check` failing, just with
  `attribute 'intelID' missing` instead. So the bus IDs are optional here:
  `intelBusID = lib.mkIf (vars ? intelID) vars.intelID;`. mkIf's value is lazy,
  so a missing attribute is never forced, and the defaults stay in exactly one
  place (`modules/drivers/`) instead of being duplicated into the profiles.

  Also documented the three optional variables (commented out) in
  `hosts/nixos/variables.nix` and in `README.md` step 3, since that override path
  is otherwise undiscoverable.

  Verified: `nix flake check` → `all checks passed!`; all six configs produce a
  toplevel drv; `vm`'s drv hash is byte-identical to before the change
  (`5b5vdlkikakqj050bak81faf3nhxq5kc`), so `amd`/`vm` are untouched. Driver
  toggles confirmed per profile — `nvidia-laptop`: offload on,
  `PCI:1:0:0`/`PCI:0:2:0` from module defaults; `amd-nvidia-hybrid`: offload on,
  `amdgpuBusId = PCI:5:0:0`, open kernel module, finegrained PM; `intel`:
  videoDrivers `["modesetting" "fbdev"]` plus the five VA-API packages; `nvidia`:
  plain, no prime.

- [x] **2. `profile` is hardcoded to `"amd"` for every configuration** — `flake.nix:47`, `flake.nix:58` — **DONE 2026-09-12**

  `mkNixosConfig` took `gpuProfile` for the import path but passed the let-bound
  `profile = "amd"` into `specialArgs`, so every config claimed to be the amd one.
  `nix eval .#nixosConfigurations.vm.config.services.smartd.enable` returned
  `true` despite the `profile == "vm"` guard at `modules/core/services.nix:25`,
  and the `fr` / `fu` aliases always said `--hostname amd`.

  Resolution: `profile = gpuProfile;`, dropped the now-unused `profile`
  let-binding, and rewrote the stale comment above `mkNixosConfig` (it described
  the bug as intentional).

  Verified: `nix flake check` → `all checks passed!`. `nixosConfigurations.amd`'s
  toplevel drv is byte-identical across the change
  (`nlm9vh9nl06g6nbydhcz7jj5p9vajk04`) — it was already getting `"amd"`, so the
  running system is unaffected — while the other five drvs all changed.
  `services.smartd.enable` is now false for `vm` only, and each config's `fr`
  alias resolves to its own name (`nh os switch --hostname nvidia-laptop`, etc.).

- [x] **3. `hyprland-change-layout` is entirely non-functional on Hyprland 0.56** — `modules/home/scripts/hyprland-change-layout.nix` — **DONE 2026-09-12**

  `hyprctl keyword` was removed along with the hyprlang config, and it exits 0,
  so `set -e` never caught it:
  ```
  $ hyprctl keyword general:layout scrolling
  unknown request          (exit 0)
  ```

  **What replaced it:** `hyprctl eval`, which runs Lua against the live config.
  Confirmed against the 0.56 source — `src/ipc/s1/Commands.cpp` registers `eval`
  and `repl` and no longer registers `keyword` or `layouts` (`hyprctl.usage`
  still advertises `keyword`, but that file is only fed to the completion
  generator and is stale). So setting a layout is now:

      hyprctl eval 'hl.config({ general = { layout = "master" } })'

  No `hyprctl -r` needed: `general:layout` is declared with
  `.refresh = REFRESH_LAYOUTS` (`src/config/values/ConfigValues.cpp:179`), so the
  prop refresher re-runs `updateWorkspaceLayouts()` and re-tiles by itself.
  Verified live — the per-workspace `tiledLayout` field in `hyprctl workspaces -j`
  comes from the instantiated algorithm via `typeid`
  (`src/ipc/s1/Commands.cpp:509-511`), not from the config value, so it is real
  proof the swap happened.

  Resolution: rewrote the script around `hyprctl eval`, deleted the dead
  bind/unbind juggling and the `init` subcommand, dropped the swaync icon path
  (swaync isn't installed), and removed `hyprland-change-layout init` from
  `modules/home/hyprland/exec-once.nix`. Decided to leave SUPER+J/K as
  directional focus rather than restoring the per-layout rebinding — it never
  fired under 0.56, and it conflicted with the H/J/K/L directional scheme that
  does work. `togglesplit` and `swapnext` are consequently not bound to anything;
  both still exist as layout messages if they're ever wanted (see item 37).

  Two guards added, because the original failure mode was *silent*:
  - The layout name is validated against the known list **before** it reaches the
    compositor. `hl.config` accepts any string for `general:layout` without
    complaint (exit 0, `ok`), stores the garbage, and silently falls back to
    tiling with **dwindle** — verified by setting it to `"nonsense"`.
  - The script reads the layout back after setting it and fails loudly on a
    mismatch, so a future API change can't reproduce a year of quiet no-ops.

  Verified: `bash -n` clean, shellcheck clean, `nix flake check` passes. All four
  layouts apply for real (`cfg` and live `tiledLayout` agree each time), `toggle`
  cycles scrolling→monocle→dwindle→master→scrolling, and every failure path
  (bogus name, missing arg, unknown subcommand, the removed `init`) exits 1
  without touching the layout. The five SUPER+ALT binds in `binds.nix` all use
  subcommands the rewrite still supports.

- [x] **4. SUPER+ALT+F is bound to a command that doesn't exist** — `modules/home/hyprland/binds.nix:94` — **DONE 2026-09-12**

  `hyprland-float-all` was not in this flake, nixpkgs, or on PATH. Origin traced:
  zaneyos ships `modules/home/scripts/hyprland-float-all.nix` and imports it; the
  bind survived the trim of this flake but the script didn't.

  Porting zaneyos's version verbatim would not have worked either — it is
  `hyprctl dispatch togglefloating address:...`, and under the Lua config
  `hyprctl dispatch X` is literally a wrapper for `hl.dispatch(X)`
  (`src/ipc/s1/Commands.cpp:1215-1225`), so old hyprlang dispatch syntax is
  invalid Lua:
  ```
  $ hyprctl dispatch exec true
  error: 3 [string "return hl.dispatch(exec true)"]:1: ')' expected near 'true'
   → Note: dispatch in lua is a shorthand for hl.dispatch(...)
  ```
  Same root cause as item 3 — this was a second casualty of the 0.56 rewrite.

  Resolution: implemented it as inline Lua in `binds.nix` instead of a script.
  Binds run Lua in-process now, so there is no subprocess, no PATH lookup, and
  one less package in `home.packages` — `modules/home/scripts/` was left
  untouched. Uses `hl.get_active_workspace()`, `hl.get_workspace_windows(ws.id)`,
  `w.floating` and `hl.dsp.window.float({action = ..., window = w})`; the `window`
  field takes the window object directly (`windowSelectorFromLuaSelectorOrObject`)
  and `action` accepts `toggle` / `enable`|`on` / `disable`|`off`
  (`LuaBindingsInternal.cpp:318-324`).

  Deliberately **not** a per-window toggle like the original: it now leaves a
  uniform state — if anything is still tiled, float everything, otherwise tile
  everything. Per-window toggling merely inverts an already-mixed workspace.

  Verified: the generated 593-line Lua config passes a luajit syntax check;
  `hl.bind(key, function)` registers and unbinds cleanly (tested on a scratch
  F24 bind); `nix flake check` passes. Behaviour tested live — repeated presses
  alternate all-float / all-tiled with no drift, and from a deliberately mixed
  workspace (`Zed=tiled, ghostty=FLOAT`) one press squares it up to all-float
  rather than inverting it.

- [x] **5. Global `FZF_DEFAULT_OPTS` breaks fzf as a picker** — `modules/home/cli/fzf.nix:15-17` — **DONE 2026-09-12**

  `programs.fzf.defaultOptions` becomes `FZF_DEFAULT_OPTS`, which fzf's
  `key-bindings.zsh` concatenates *ahead of* each widget's own options
  (`__fzf_defaults`, verified in the installed fzf 0.74.3). No widget rebinds
  `enter` or overrides `--preview`, so `--bind='enter:execute(nvim {})'` and
  `--preview='bat ... {}'` leaked into Ctrl-R, Ctrl-T, Alt-C and third parties
  like zoxide's `cdi`.

  Proven with a pty harness rather than by reading alone — same input, same
  appended history-widget options, only `FZF_DEFAULT_OPTS` differing:

  | defaultOptions | enter action fired | selection returned |
  |---|---|---|
  | old (with the binds) | YES | `<EMPTY>` |
  | control / new | no | `git status` |

  So Ctrl-R ran nvim against the selected *history line* and handed the widget
  nothing, meaning nothing was ever inserted at the prompt, while the preview
  pane ran bat against the command text.

  Resolution: `defaultOptions` is appearance-only now. The path-aware bits moved
  to where the input actually is paths — `fileWidget.options` (Ctrl-T) and
  `changeDirWidget.options` (Alt-C) — and the fuzzy-open-in-nvim flow became its
  own `fe` alias instead of a side effect on every picker:
  `fzf --multi --print0 ... | xargs -0 -r -o nvim`. Also dropped the redundant
  `--header=''` (no-op) and the needless quotes on `--info='hidden'`.

  The Ctrl-T preview is directory-aware (`[ -d {} ] && eza --tree ... || bat ...`)
  because Ctrl-T's walker yields directories too and bat only errors on those.

  Worth remembering: home-manager space-joins each option list into one env var
  (`sessionVariables = mapAttrs toString`) and fzf re-splits it shell-like, so any
  option value containing a space needs its own quotes inside the Nix string —
  that is why `--prompt='/ '` and `--preview='...'` keep theirs.

  Verified: `nix flake check` passes; generated `FZF_DEFAULT_OPTS` contains no
  bind or preview and `FZF_CTRL_R_OPTS` is unset; both Ctrl-R and Ctrl-T
  simulations return their selection; the preview renders files *and* directories,
  and fzf's own `{}` quoting handles names with spaces (checked with a real
  `sp ace file.txt`). The `fe` pipeline was checked for all four edge cases —
  empty selection runs nothing, single and multiple names with spaces arrive as
  correct separate argv entries, and `xargs -o` works under a pty so nvim gets a
  terminal.

- [x] **6. `gtk-3.0/settings.ini` and `gtk-4.0/settings.ini` each get two `[Settings]` sections** — `modules/home/xdg.nix:62-79` — **DONE 2026-09-12**

  Home Manager's `gtk` module owns both files (`modules/misc/gtk/gtk3.nix:123`,
  `gtk4.nix:140`), and a file's `text` option is `types.lines`, so the
  hand-written block in `xdg.nix` was *concatenated* onto HM's rather than
  replacing it.

  Resolution: deleted both `xdg.configFile."gtk-*/settings.ini"` blocks and
  expressed every key through the module that owns the file —
  `gtk.font = { name = "MiSans"; size = 10; }`, `gtk.theme.name = "Adwaita"`,
  and `gtk.colorScheme = "dark"` in place of the hand-rolled
  `gtk-application-prefer-dark-theme` in `gtk3.extraConfig`/`gtk4.extraConfig`
  (see `modules/misc/gtk/lib.nix:56-80` for the key mapping).

  Also dropped `gtk.cursorTheme` while here: `home.pointerCursor` in `xdg.nix`
  already feeds `gtk.cursorTheme` its name, package **and** size via `mkDefault`
  (`modules/config/home-cursor.nix:223-227`, where `gtk.size` defaults to
  `pointerCursor.size`), and is also what drives `HYPRCURSOR_*`/`XCURSOR_*`. The
  cursor is now declared in exactly one place.

  Verified: `nix flake check` passes; each file now has exactly **one**
  `[Settings]` group (was 2). Key sets compared against the previously deployed
  concatenated files:
  - `gtk-3.0`: **identical key set** — pure fix, no behaviour change. Values are
    now `=true` rather than `=1`, both of which `g_key_file_get_boolean` accepts.
  - `gtk-4.0`: one deliberate swap — `gtk-theme-name` is gone and
    `gtk-interface-color-scheme=2` is added. That follows from honouring the
    pre-existing `gtk4.theme = null` (GTK4 takes its theme from libadwaita, not
    `gtk-theme-name`) together with `colorScheme = "dark"`. If the key is wanted
    back on GTK4, drop the `gtk4.theme = null` line or set
    `gtk4.theme.name = "Adwaita"`.

  Checked that this does not collide with noctalia: noctalia's `gtk3`/`gtk4`
  templates write `gtk.css` + `noctalia.css` (mutable, colours only) and never
  touch `settings.ini`, so the two own disjoint halves.

- [ ] **7. Two groups in `extraGroups` don't exist** — `modules/core/user.nix:31-33`

  `docker` (because `virtualisation.docker.enable = false`) and `adbusers`
  (because `programs.adb.enable` is never set) are silently dropped.

  Evidence: `id yangkx` → `groups=100(users),1(wheel),20(lp),57(networkmanager),59(scanner),67(libvirtd),983(i2c)`

  Fix: drop `docker` until docker is enabled; set `programs.adb.enable = true` —
  it creates the group and installs the udev rules, which is probably wanted here
  for Android work.

- [ ] **8. swappy's save dir doesn't match the keybinds' dir** — `modules/home/swappy.nix:6` vs `modules/home/hyprland/binds.nix:82-84`

  swappy writes to `~/Pictures/ScreenShots`, the hyprshot binds use
  `~/Pictures/Screenshots`. Only `Screenshots` exists, so saving from swappy
  (the `screenshootin` path) targets a directory that isn't there.

  Evidence: `ls -d ~/Pictures/*` → `Screenshots`, `Wallpapers`.

  Fix: pick one spelling and use it in both places.

- [ ] **9. Stale geometry after the monitor scale change** — `modules/home/hyprland/windowrules.nix:270-275`

  The comment says "70% of the 2560x1440 logical screen (3840x2160 @ 1.5)", but
  `hosts/nixos/variables.nix:7` now sets `scale = "2"` → logical 1920x1080, so 70%
  is 1344x756 and `min_size = { 1792, 1008 }` overrides it to near-fullscreen for
  every `settings*`-tagged window.

  Fix: recompute `min_size` for scale 2 (or drop it) and update the comment.

---

## Worth fixing (design / footguns)

- [ ] **10. `useGlobalPkgs = false` is inert, and misleadingly so** — `modules/core/user.nix:14-16`

  `extraSpecialArgs` wins over `_module.args` in the module system, so passing
  `pkgs` there means HM modules already get the *system* pkgs with the overlays and
  `allowUnfree`. Meanwhile HM still exposes `nixpkgs.config` / `nixpkgs.overlays`
  options that would be silently ignored if ever set.

  Evidence: minimal `lib.evalModules` test with the same arg in both places
  resolves to the `specialArgs` value.

  Fix: `useGlobalPkgs = true` and drop `pkgs` from `extraSpecialArgs` — same
  result, honest about it.

- [x] **11. `rocmPackages.clr` in the closure for one symlink** — `modules/drivers/amd-drivers.nix:15` — **DONE 2026-09-12**

  `/opt/rocm/hip` is an FHS compatibility symlink only needed by software that
  dlopens the HIP runtime from a fixed path instead of the Nix store — DaVinci
  Resolve, Blender's HIP backend, ROCm PyTorch. None of those are installed
  (checked the config and `programs.uv.tool.packages`), `/opt/rocm` contained
  nothing but the symlink, and nothing on the system referenced the path.

  Resolution: made it opt-in as `drivers.amdgpu.rocmHipSdk`, defaulting to false,
  rather than deleting it outright — so it's one flag away if Resolve or Blender
  ever land here, with the cost documented in the option description. Verified
  that flipping the flag back restores the exact tmpfiles rule.

  **Correction to the original estimate:** this item claimed 879 MiB, which was
  `clr`'s *standalone* closure (`nix path-info -S`). The real marginal saving is
  smaller because roughly 256 MiB of that closure is shared with the rest of the
  system. Measured by building both toplevels and diffing:

  | | closure | paths |
  |---|---|---|
  | with the symlink | 16.499 GiB | 2427 |
  | without | 15.890 GiB | 2406 |
  | **saved** | **0.608 GiB (623 MiB, 3.7%)** | 21 |

  The 21 paths are all ROCm toolchain — `clr`, `rocm-{core,comgr,runtime,
  device-libs,toolchain}`, `rocminfo`, `rocprofiler-register`, `hipClang` and the
  whole `llvm-22.0.0-rocm` / `clang-rocm` / `lld-rocm` / `openmp-rocm` set.
  (The closure diff also lists 7 rehashed paths — `etc`, `system-units`,
  `tmpfiles.d` and friends — which appear on *both* sides and are not savings.)

  Verified nothing else regressed: `rocm-smi` is still in the closure, so btop's
  GPU monitoring is unaffected; mesa path count unchanged at 4;
  `services.xserver.videoDrivers` is still `["amdgpu"]`; no `/opt/rocm` rule
  remains among the 33 tmpfiles rules; `nix flake check` passes.

  **Leftover to clean up by hand after the next rebuild:** systemd-tmpfiles does
  not remove a rule that no longer exists, and `/opt/rocm/hip` is not a GC root,
  so it will dangle once the store path is collected:
  ```sh
  sudo rm /opt/rocm/hip && sudo rmdir /opt/rocm
  ```

- [ ] **12. sshd is exposed to the LAN with password auth** — `modules/core/services.nix:10-18`, `modules/core/network.nix:21-25`

  Evidence: `ss -tlnp` → `LISTEN 0 128 0.0.0.0:22`, with
  `PasswordAuthentication = true` and `KbdInteractiveAuthentication = true`.

  Fix: keys-only (`PasswordAuthentication = false` plus
  `users.users.yangkx.openssh.authorizedKeys.keys`). Separately, TCP 80 and 443 are
  open with nothing listening — no web server exists anywhere in this config, so
  those two holes can go.

- [ ] **13. `services.flatpak.update.onActivation = true`** — `modules/core/flatpak.nix:25`

  Every `nixos-rebuild switch` hits the network to update flatpaks: slower
  rebuilds, and failures when offline. Move it to a systemd timer.

- [ ] **14. `system.nix` duplicates `cachix.nix`** — `modules/core/system.nix:11-12`

  Evidence — `/etc/nix/nix.conf` lists `hyprland.cachix.org` twice in both
  `substituters` and `trusted-public-keys`, plus both `cache.nixos.org/` and
  `cache.nixos.org`.

  Fix: delete the two lines from `system.nix`; `modules/core/cachix.nix` already
  covers them.

- [ ] **15. `auto-optimise-store = true`** — `modules/core/system.nix:5`

  Prefer `nix.optimise.automatic = true` (a timer) over inline dedup on every
  store write.

- [ ] **16. `openlogi` pins a 42-day-old nixpkgs**

  The lock carries four distinct nixpkgs revs: ours, hyprland's, noctalia's and
  openlogi's. Hyprland's and noctalia's are deliberate — following them forfeits
  their cachix hits. `openlogi` is our own repo, so
  `inputs.nixpkgs.follows = "nixpkgs"` is free there and removes one full nixpkgs
  evaluation.

- [ ] **17. `ncg` fights `programs.nh.clean`** — `modules/home/cli/shell.nix:13` vs `modules/core/nh.nix:10`

  The alias runs `nix-collect-garbage -d` (deletes every old generation) while nh's
  cleaner keeps 3. Pick one policy.

- [ ] **18. Global QML paths plus loose Qt packages** — `modules/core/qt.nix:7-26`

  `QML_IMPORT_PATH` / `QML2_IMPORT_PATH` system-wide plus unwrapped `qt6.*` in
  `systemPackages` is the classic workaround for an unwrapped QML app, and it can
  break other Qt apps. Noctalia's own wrapper should handle its imports now — test
  whether this whole module can be deleted.

- [ ] **19. `eza` options** — `modules/home/cli/eza.nix:11-20`

  `--git-ignore` means every `ls` hides gitignored files (surprising inside a build
  dir), and `--icons=always` duplicates `icons = "auto"`.

- [ ] **20. Env vars declared in three places**

  `NIXOS_OZONE_WL` in `modules/core/system.nix:35` and
  `modules/home/hyprland/env.nix:5`; `QT_QPA_PLATFORM` and
  `QT_WAYLAND_DISABLE_WINDOWDECORATION` in `modules/core/qt.nix:30-31` and
  `env.nix:12-13`. Pick one owner per variable.

  Also `SDL_VIDEODRIVER = "x11"` (`env.nix:15`) forces all SDL apps off Wayland;
  SDL2/3 handle Wayland fine now.

- [ ] **21. Unexplained `mkForce`s**

  `modules/home/cli/bat.nix:15` forces the theme to Dracula, opting bat out of
  noctalia's theming while everything else follows Ayu;
  `modules/home/qt.nix:4` forces `qtct`. Both suggest a conflict that deserves a
  one-line comment, or removal if the conflict is gone.

- [ ] **22. No `devShells` output** — `flake.nix:66-77`

  `nix develop` fails; `shell.nix` is only reachable via `nix-shell`.

  Evidence: `nix develop -c true` →
  `error: flake ... does not provide attribute 'devShells.x86_64-linux.default'`

  Fix: one line —
  `devShells.x86_64-linux.default = import ./shell.nix { pkgs = nixpkgs.legacyPackages.x86_64-linux; };`

---

## Cruft (low risk, easy wins)

- [ ] **23.** `modules/core/ly.nix` is not imported anywhere — greetd +
      noctalia-greeter is what's actually used. Delete it.
- [ ] **24.** 10 of the 11 `modules/home/hyprland/animations-*.nix` files are
      unimported (~300 lines). Only `animations-ml4w-fast.nix` is in
      `modules/home/hyprland/default.nix`.
- [ ] **25.** `security.pam.services.swaylock` (`modules/core/security.nix:18`) —
      swaylock isn't installed. `programs.hyprlock.enable = true`
      (`modules/core/packages.nix:21`) is also vestigial now that noctalia owns
      lock and idle.
- [ ] **26.** ~~The `dwindle` and `master` blocks are inert~~ — **superseded by
      item 3**: layout switching works again, so
      `modules/home/hyprland/hyprland.nix:110-168` is now live config whenever
      SUPER+ALT+1/2/4 is used. Re-read those values and check they're still what
      you want, rather than deleting them.
- [ ] **27.** Duplicate `systemPackages`: `gpu-screen-recorder` at
      `modules/core/packages.nix:33` and `:46`; `power-profiles-daemon` at `:47`
      and as a service; `upower` at `:34` and as a service; `eza` at `:37` plus
      `programs.eza`.
- [ ] **28.** ~40 window rules in `modules/home/hyprland/windowrules.nix` target
      apps that aren't installed (Brave, Firefox, Discord, Telegram, Ferdium,
      WhatsApp, Teams, Lutris, Heroic, VSCodium, Waypaper). The two
      `match = { class = [[^(*)$]] }` idle-inhibit rules (`:249-259`) are
      hyprlang-era leftovers — no regex error appears in the Hyprland log, and the
      third rule (`fullscreen = true`) is the one doing the work.
- [ ] **29.** `inputs.self.submodules = true` (`flake.nix:3`) with no
      `.gitmodules` in the repo.
- [ ] **30.** `fonts/MiSans/.uuid` is committed and `.DS_Store` sits in the font
      source dir — both land in the derivation's `src`. (`misans` is genuinely not
      in nixpkgs, so bundling the TTFs is justified; only the junk files need to
      go. For reference: 77 MB fonts + 8.6 MB recording is 86 of the repo's
      189 MB.)
- [ ] **31.** `modules/home/scripts/restart.noctalia.nix` writes its script to
      `mktemp` and execs it — `writeShellApplication` does this directly. It is
      also redundant with the SUPER+SHIFT+R bind, which already does
      `pkill -x noctalia; sleep 0.3; noctalia`.
- [ ] **32.** `/usr/local/bin` in `home.sessionPath`
      (`modules/home/cli/shell.nix:24`) does not exist on NixOS.
- [ ] **33.** HM's `xdg.portal` (`modules/home/xdg.nix:34-41`) duplicates the
      system one in `modules/core/flatpak.nix:6-10`. Verified to contribute
      nothing: `~/.config/xdg-desktop-portal/` doesn't exist and the running
      portals are the system's.
- [ ] **34.** `hosts/nixos/variables.nix` is `import`ed directly by five modules.
      Passing it once through `specialArgs` (or exposing it as a module option)
      would make the values overridable per-profile instead of being a file-path
      convention.
- [ ] **35.** README drift: the `extraMonitorSettings` example (`README.md:52`)
      uses the old hyprlang `monitor = DP-1, ...` syntax while the real config
      uses `hl.monitor({...})`.
- [ ] **36.** Two files are not alejandra-clean: `modules/core/qt.nix` (arg set
      should collapse to one line) and `modules/core/flatpak.nix:20` (comment
      spacing). Found while running `nix fmt ./` during item 1 and reverted to
      keep that change focused — `nix fmt ./` fixes both in one go.
- [ ] **37.** `togglesplit` (dwindle) and `swapnext` (master/monocle) are not
      bound to any key. They were only ever reachable through item 3's dead
      rebinding code, so they have never worked. Both still exist as layout
      messages in 0.56; `SUPER+O` and `SUPER+SHIFT+M` are free if wanted:
      `hl.bind(mainMod .. " + O", hl.dsp.layout("togglesplit"))`.

---

## Checked and fine — don't "fix" these

Recorded so the same ground isn't re-covered:

- `nix eval` on the amd config produces **zero** warnings.
- Locales are already trimmed to 4 (`i18n.supportedLocales`). The 222 MB
  `glibc-locales` in the closure is the full one pulled by the Steam and
  appimage-run FHS envs, not by this config.
- The duplicate `mesa-26.2.2` and `llvm-21.1.8-lib` pairs are 32-bit multilib for
  Steam (`graphics-drivers` vs `graphics-drivers-32bit`), not a consequence of the
  multiple nixpkgs inputs.
- `btop.override { rocmSupport = true; cudaSupport = true; }` is substitutable from
  cache.nixos.org, so it costs no build time; it pulls only `rocm-smi`.
  `cudaSupport` on an AMD-only box is pointless, not expensive.
- `programs.zsh.dotDir = config.home.homeDirectory` (`modules/home/cli/zsh.nix:4`)
  is the documented way to silence HM's upcoming default change. Correct as-is.
- ghostty's absolute `home.file` key (`modules/home/terminals/ghostty.nix:11`)
  resolves correctly — the shader lands at
  `~/.config/ghostty/shaders/shader.glsl`.
- `monocle` is a valid Hyprland 0.56 layout.
- The nixpkgs source in the closure (204 MB, via `/etc/nix/registry.json`) is
  normal for a flake-based NixOS and is not in conflict with
  `flake-registry = ""`, which only disables the *online* registry.
