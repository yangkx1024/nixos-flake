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

- [x] **7. Two groups in `extraGroups` don't exist** — `modules/core/user.nix:31-33` — **DONE 2026-09-13**

  `docker` (because `virtualisation.docker.enable = false`) and `adbusers`
  (because `programs.adb.enable` is never set) are silently dropped.

  Evidence: `id yangkx` → `groups=100(users),1(wheel),20(lp),57(networkmanager),59(scanner),67(libvirtd),983(i2c)`

  **Correction to the original fix:** `programs.adb.enable = true` would not
  evaluate. The option is gone from nixpkgs (`nixos/modules/rename.nix`,
  `mkRemovedOptionModule`): *"no longer needed as systemd 258 handles uaccess
  rules automatically. Please add `pkgs.android-tools` to your system packages
  to get the adb command."* Confirmed on the running systemd 261.2 —
  `lib/udev/rules.d/70-uaccess.rules:84` sets `ID_DEBUG_APPLIANCE="android"` for
  the ADB, ADB-over-DbC and Fastboot USB interface classes (`dc0201`, `ff4201`,
  `ff4203`), and `:121` tags every `ID_DEBUG_APPLIANCE` device `uaccess`, so the
  logged-in seat user gets the device node with no group at all.

  Resolution: dropped `adbusers`, with a one-line comment so nobody re-adds it.
  `docker` became `lib.optional config.virtualisation.docker.enable "docker"`
  instead of being deleted, so enabling docker in `modules/core/virtualisation.nix`
  brings the group membership with it and it can't go stale again.

  Did **not** add `android-tools`. No adb or fastboot exists on this machine
  today (not on PATH, no `~/Android/Sdk`), and an Android Studio SDK brings its
  own `platform-tools/adb`. A second adb from nixpkgs is the usual cause of
  `adb server version (N) doesn't match this client (M); killing...`. Add it
  only if adb is wanted without an SDK.

  Verified: `nix flake check` → `all checks passed!`; all six configs evaluate to
  `["i2c","libvirtd","lp","networkmanager","scanner","wheel"]`, which matches the
  live `id` output exactly. `nixosConfigurations.amd`'s toplevel drv is
  **byte-identical** across the change (`3gsqvisfv27vcivrip0h8d0xv4hfmpjj`), so
  the dropped entries never reached the system and the next switch is a no-op.
  With `virtualisation.docker.enable = lib.mkForce true` layered on via
  `extendModules`, the list gains `"docker"` and `users.groups.docker` exists;
  `adbusers` exists in neither.

- [x] **8. swappy's save dir doesn't match the keybinds' dir** — `modules/home/swappy.nix:6` vs `modules/home/hyprland/binds.nix:82-84` — **DONE 2026-09-13**

  swappy writes to `~/Pictures/ScreenShots`, the hyprshot binds use
  `~/Pictures/Screenshots`. Only `Screenshots` exists, so saving from swappy
  (the `screenshootin` path) targets a directory that isn't there.

  Evidence: `ls -d ~/Pictures/*` → `Screenshots`, `Wallpapers`.

  **Correction to the symptom:** a swappy save would not have failed. Both
  tools create a missing directory themselves: swappy 1.8.0's `config_load`
  runs `g_mkdir_with_parents` on `save_dir` at startup (`src/config.c:113-118`,
  before the window even opens), and hyprshot 1.3.0 does `mkdir -p "$SAVEDIR"`.
  The real bug was a split: SUPER+G (grim → slurp → swappy) would have saved into
  a new `ScreenShots` folder, while SUPER+CTRL/SHIFT/ALT+G (hyprshot) saved into
  `Screenshots`, and on a case-sensitive filesystem those are two separate
  directories. `ScreenShots` still didn't exist, meaning swappy had never been
  launched with this config, so there was nothing to migrate.

  Resolution: `ScreenShots` → `Screenshots` in `swappy.nix`. Chose that spelling
  because the directory already exists, the three hyprshot binds already use
  it, and it matches the GNOME / KDE Spectacle default. Left the path as
  duplicated literals rather than sharing one value across the two files: it is
  one string in two places, and `hosts/nixos/variables.nix`, the only
  cross-module channel today, is what item 34 wants to stop leaning on.

  Verified: `nix flake check` passes; the generated
  `home.file.".config/swappy/config"` now reads
  `save_dir=/home/yangkx/Pictures/Screenshots`, identical to the binds'
  `$HOME/Pictures/Screenshots` with `home.homeDirectory = /home/yangkx`;
  no `ScreenShots` spelling remains in any `.nix` file. The `amd` toplevel drv
  changed (`3gsqvisf…` → `mi0m74km…`), as expected for a changed HM file.
  Not tested by taking a live screenshot, since swappy's save needs its GUI.
  After the next switch, SUPER+G then Ctrl+S should put a
  `swappy-YYYYmmdd-HHMMSS.png` into `~/Pictures/Screenshots`.

- [x] **9. Stale geometry after the monitor scale change** — `modules/home/hyprland/windowrules.nix:270-275` — **DONE 2026-09-13**

  The comment says "70% of the 2560x1440 logical screen (3840x2160 @ 1.5)", but
  `hosts/nixos/variables.nix:7` now sets `scale = "2"` → logical 1920x1080, so 70%
  is 1344x756 and `min_size = { 1792, 1008 }` overrides it to near-fullscreen for
  every `settings*`-tagged window.

  **Root cause was deeper than the scale change:** `size = { "70%", "70%" }`
  has never worked under the Lua config, not even at scale 1.5. The pixel
  `min_size` (added in `e3faef3`, exactly 70% of the old logical screen) was the
  workaround doing all the sizing. In 0.56, `size` / `min_size` / `max_size` /
  `move` are `CLuaConfigExpressionVec2`. The string goes to muparser verbatim
  (`CWindowTarget::calculateSingleExpr`, `src/layout/target/WindowTarget.cpp`)
  with only `monitor_w`, `monitor_h`, `window_w`, `window_h`, `window_x`,
  `window_y`, `cursor_x`, `cursor_y` defined, and nothing on that path handles a
  `%` suffix. `"70%"` is dropped **silently**: no line in `hyprland.log`, and
  `Hyprland --verify-config` says `config ok` for it.

  Proven live with probe windows on a silent `special:probe` workspace
  (1920x1080 logical). The throwaway rules were disabled afterwards, and the real
  `Settings-Tag` was re-enabled by name, so no reload was needed:

  | rule | wezterm | pavucontrol | Mission Center | nm-connection-editor |
  |---|---|---|---|---|
  | current `Settings-Tag` | 1792x1008 | 1792x1008 | 1792x1008 | 1792x1008 |
  | `float` only (natural) | 816x544 | 500x400 | 600x400 | 600x400 |
  | `size = { "70%", "70%" }` | **816x544** (ignored) | | | |
  | `size = monitor_*0.7` | 1344x756 | 1344x756 | 1344x756 | 1344x756 |
  | `min_size = monitor_*0.7` | 1344x756 | 1344x756 | 1344x756 | 1344x756 |
  | both | | 1344x756 | 1344x756 | 1344x756 |

  All sizes were stable after 2 s, so no app resizes itself after map. `move`
  behaves the same: `{ "72%", "7%" }` left the window centred, identical to
  no rule, while `{ "monitor_w*0.72", "monitor_h*0.07" }` placed it at y=76
  (1080 × 0.07 = 75.6). x was clamped to `monitor_w - window_w`, because Hyprland
  keeps a floating window on-screen.

  Resolution: `size = { "monitor_w*0.7", "monitor_h*0.7" }` with `min_size`
  **dropped**. `size` and `min_size` are indistinguishable at open for every
  app tested, but `min_size` is also a floor for mouse drag-resize
  (`DragController.cpp:136,416`), so it would keep stopping a settings window from
  being dragged smaller than 70%. It only existed to paper over the broken
  `size`. The stale comment is replaced by one explaining the `%` trap.

  Same bug fixed in the five other percentage rules in the file:
  `Picture-in-Picture` `move` (Chrome PiP, live), `Add-Folder` and `Open-File`
  dialog sizes, `Loupe`, and `Ferdium` (not installed, see item 28). No
  `"N%"` string remains in `windowrules.nix`.

  Verified: `nix flake check` passes; the generated `hypr/hyprland.lua` diff
  against the currently deployed one (confirmed byte-identical to the pre-change
  build) is exactly those six rules; luajit syntax check and
  `Hyprland --verify-config` both pass. Effective after the next switch. Expect
  settings-tagged windows to open at 1344x756, and to be resizable below that.

---

## Worth fixing (design / footguns)

- [x] **10. `useGlobalPkgs = false` is inert, and misleadingly so** — `modules/core/user.nix:14-16` — **DONE 2026-09-13**

  `extraSpecialArgs` wins over `_module.args` in the module system, so passing
  `pkgs` there means HM modules already get the *system* pkgs with the overlays and
  `allowUnfree`. Meanwhile HM still exposes `nixpkgs.config` / `nixpkgs.overlays`
  options that would be silently ignored if ever set.

  Evidence: minimal `lib.evalModules` test with the same arg in both places
  resolves to the `specialArgs` value.

  Resolution: `useGlobalPkgs = true`, `pkgs` dropped from `extraSpecialArgs`.

  What the flag actually switches, read from HM source
  (`modules/modules.nix:71-73`, `nixos/common.nix:45`): `false` imports
  `misc/nixpkgs.nix`, which builds its own `_pkgs` from `pkgsPath` plus HM's
  `nixpkgs.*` and sets `_module.args.pkgs` / `pkgs_i686`. `true` imports
  `misc/nixpkgs-disabled.nix` instead, and `pkgs` falls through to
  `_module.args.pkgs = mkDefault <system pkgs>`. Before switching, checked the
  three ways this could have broken:
  - `pkgs_i686` goes away. Nothing uses it: no hits in this flake, and in HM
    itself only the module that defines it.
  - `pkgs` stops being a *special* arg, so it can no longer be used while
    `imports` are resolved. Neither this flake's home modules nor noctalia's
    `homeModules.default` / `nix/home-module.nix` touch `pkgs` in `imports`.
  - HM-level `nixpkgs.*` options become disabled. None are set: the
    `nixpkgs.config.allowUnfree` and `nixpkgs.overlays` hits are NixOS-level
    (`modules/core/packages.nix:28`, `modules/core/overlays.nix:2`).

  Verified: all **six** toplevel drvs are byte-identical before and after
  (amd `1nriwsj4pjjx63s3ik6lz3q1gqsb9vyq`, vm `n90l2l8q…`, nvidia `gy50j3gs…`,
  nvidia-laptop `sr89bvvj…`, amd-nvidia-hybrid `misljcy6…`, intel `fiyrm1vp…`),
  so this is a pure no-op for the built system. `nix flake check` passes, and
  system and HM `warnings` are both still `[]`.

  The "honest about it" half, proven with an HM module that sets
  `nixpkgs.overlays` and reports whether `pkgs` sees it, layered on via
  `extendModules`:

  | setup | overlay reaches `pkgs` | HM warning |
  |---|---|---|
  | old (`false` + `pkgs` in `extraSpecialArgs`) | no | **none**, silently ignored |
  | new (`useGlobalPkgs = true`) | no | *"You have set either `nixpkgs.config` or `nixpkgs.overlays` while using `home-manager.useGlobalPkgs`…"* |

  Same effective pkgs either way; the difference is that a misplaced HM
  overlay now warns instead of vanishing. Overlays and unfree config belong in
  `modules/core/`.

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

- [x] **12. sshd is exposed to the LAN with password auth** — `modules/core/services.nix:10-18`, `modules/core/network.nix:21-25` — **DONE 2026-09-13**

  Evidence: `ss -tlnp` → `LISTEN 0 128 0.0.0.0:22`, with
  `PasswordAuthentication = true` and `KbdInteractiveAuthentication = true`.

  Fix: keys-only (`PasswordAuthentication = false` plus
  `users.users.yangkx.openssh.authorizedKeys.keys`). Separately, TCP 80 and 443 are
  open with nothing listening — no web server exists anywhere in this config, so
  those two holes can go.

  Context gathered before deciding: the journal goes back to 2026-06-13 (76
  boots) and contains **zero** sshd `Accepted` lines and zero failures, so SSH
  in has never actually been used. There was no `~/.ssh/authorized_keys`,
  meaning password auth was the *only* way in. No tailscale/zerotier. Disabling
  sshd outright was offered. The decision was to keep it, keys-only, with the
  one key this machine holds.

  Resolution:
  - `services.nix`: `PasswordAuthentication = false`,
    `KbdInteractiveAuthentication = false`; the misleading "kb and password"
    comment is replaced. `PermitRootLogin = "no"` unchanged.
  - `user.nix`: `openssh.authorizedKeys.keys` = `~/.ssh/id_ed25519.pub`
    (ED25519, `SHA256:CEVZlV93u1IE4GJlb/52gqM7E00mowEQLz5uiIwg0jU`,
    `kexuan.yang@yangkx.net`). NixOS installs it as
    `/etc/ssh/authorized_keys.d/yangkx`, which the generated `AuthorizedKeysFile`
    already lists after `%h/.ssh/authorized_keys`. To SSH in from another device,
    that device needs this private key, or its own public key added to the list.
  - `network.nix`: `allowedTCPPorts = []`. 80 and 443 are gone, and so is
    the 22, because `services.openssh.openFirewall` defaults to `true` and already
    opens `services.openssh.ports`. The port is now owned by the service, so
    disabling sshd closes it too. Nothing could have used 80/443 anyway:
    `net.ipv4.ip_unprivileged_port_start = 1024`, so only a root daemon could
    bind them, and none exists.

  Verified:
  - `nix flake check` passes. Effective `networking.firewall.allowedTCPPorts` is
    `[22, 27036, 27037]` (was `[22, 80, 443, 27036, 27037]`; 27036/27037 are
    Steam's).
  - The generated `sshd.conf-final` reads `PasswordAuthentication no`,
    `KbdInteractiveAuthentication no`, `PermitRootLogin no`. The generated
    `authorized_keys.d/yangkx` holds exactly the key above.
  - **End-to-end**: the deployed and the newly generated `sshd_config` were
    both run in a throwaway unprivileged sshd on `127.0.0.1:2222`. Overrides were
    limited to host key, pid file, listen address, `UsePAM=no`, `StrictModes=no`
    and `AuthorizedKeysFile` pointing at a copy of the generated file, none of
    which touch the settings under test. Both pass `sshd -t`.

    | | deployed config | new config |
    |---|---|---|
    | methods offered | `publickey,password,keyboard-interactive` | `publickey` |
    | password / kbd-interactive attempt | offered | refused, never prompted |
    | `~/.ssh/id_ed25519` | logs in | **logs in** (`logged in as yangkx`) |
    | freshly generated stranger key | denied | denied |

    The live sshd on :22 advertised the same `publickey,password,keyboard-interactive`
    beforehand, so the control matches reality.

  Not done here: `nixos-rebuild switch` needs sudo. After switching, confirm with
  `ssh -o PubkeyAuthentication=no localhost` → `Permission denied (publickey).`
  This is not a lockout risk for local use, since it's a desktop with a seat.

  Out of scope, recorded so it isn't re-investigated: `ss` also shows rpcbind on
  `0.0.0.0:111`. That comes from `boot.supportedFilesystems = ["nfs"]` in
  `modules/core/nfs.nix` (the nixpkgs `nfs.nix` enables `services.rpcbind`), and
  the firewall does not open it.

- [x] **13. `services.flatpak.update.onActivation = true`** — `modules/core/flatpak.nix:25` — **DONE 2026-09-13**

  Every `nixos-rebuild switch` hits the network to update flatpaks: slower
  rebuilds, and failures when offline. Move it to a systemd timer.

  Confirmed the premise. nix-flatpak's `flatpak-managed-install.service` is a
  `Type=oneshot` without `RemainAfterExit`, `WantedBy=graphical.target`, so it
  sits inactive after each run. `switch-to-configuration-ng` queues every
  *active* target for start (`src/main.rs:1247-1262`, started at `:2551-2566`),
  and starting the already-active `graphical.target` re-pulls its `Wants=`, so
  the oneshot re-runs on **every** switch, even with no config change.
  `onActivation = true` puts `--or-update` on each of its install commands. From
  the journal (2026-06-13 onward): 545 runs, **267 of 302 switches** followed by
  one within 5 min, each showing 30–100 KB incoming IP traffic even when nothing
  was installed.

  Found in passing, already fixed, not caused by this option: on 2026-09-04 an
  invalid package id (`flathub:com.longbridgeapp.LongbridgePro`, *"Name can't
  contain :"*) made the unit fail **323 times**, from 14:27 to 21:05.
  nix-flatpak's `restartOnFailure` defaults to on with `RestartSec=60s` and no
  backoff, so a failing run retries every minute until something changes.

  Resolution:
  - `update.onActivation = false`, `update.auto = { enable = true; onCalendar = "weekly"; }`.
  - `systemd.services.flatpak-managed-install-timer` gets
    `wants`/`after = ["network-online.target"]`. The generated timer is
    `Persistent=true`, so a week missed while powered off fires at boot, usually
    before NetworkManager is up. Without the ordering, that run would fail and
    fall into the 60 s retry loop above. `NetworkManager-wait-online.service` is
    enabled here, so the target really waits for a connection.
  - Rewrote the comment (also fixes the `swit ch` typo). Left the misaligned
    `Warehouse` comment on line 20 for item 36; alejandra flags only that line,
    and the new lines are clean.

  Verified:
  - `nix flake check` passes.
  - **Switch-time script**: `--or-update` count 4 → **0**. For an app already in
    nix-flatpak's state with no pinned commit, the branch is now `elif false`, so
    no flatpak command runs at all; a newly added app still gets a plain `install`.
  - **Timer script** is byte-identical to the old switch-time script
    (`ix7wwl43ajayzpbnxx8nh76cr13h0j4x`): the weekly timer does exactly what every
    switch used to do.
  - Generated units pass `systemd-analyze verify`. The timer is
    `OnCalendar=weekly`, `Persistent=true`, `WantedBy=timers.target`. The timer
    service has `After=`/`Wants=network-online.target` and is not wanted by any
    target, so switches never start it. Next elapse: Mon 00:00.

  After switching, `systemctl list-timers flatpak-managed-install-timer` should
  show it scheduled, and later `flatpak-managed-install.service` runs in
  `journalctl` should report near-zero IP traffic.

- [x] **14. `system.nix` duplicates `cachix.nix`** — `modules/core/system.nix:11-12` — **DONE 2026-09-13**

  Evidence — `/etc/nix/nix.conf` lists `hyprland.cachix.org` twice in both
  `substituters` and `trusted-public-keys`, plus both `cache.nixos.org/` and
  `cache.nixos.org`.

  Fix: delete the two lines from `system.nix`; `modules/core/cachix.nix` already
  covers them.

  Resolution: deleted both lines from `system.nix`, **and** dropped
  `"https://cache.nixos.org"` from `cachix.nix`. The latter is the second
  duplicate: `nixos/modules/config/nix.nix:442-444` already adds
  `substituters = mkAfter [ "https://cache.nixos.org/" ]` and the
  `cache.nixos.org-1:` key on every NixOS system. Left a comment in `cachix.nix`
  so it isn't re-added.

  What the duplicates actually cost, measured with Nix 2.34.8 against a
  throwaway `local?root=` store, using the Hyprland 0.56 output (on
  hyprland.cachix, not on cache.nixos.org):
  - Exact-duplicate URIs (the two `hyprland.cachix.org`) are collapsed by Nix.
  - `https://cache.nixos.org/` and `https://cache.nixos.org` are **not**: they
    open two substituters, and with the narinfo cache disabled every
    cache.nixos.org miss was queried twice (171 → 180 narinfo GETs).
  - With default `narinfo-cache-*-ttl` and a fresh `XDG_CACHE_HOME`, both lists
    made **identical** traffic (171 / 180 GETs). The disk cache is keyed by the
    normalized URL, so the second spelling is answered locally. In practice the
    duplicates were clutter, not a performance problem.
  - Order is also unaffected. Nix stable-sorts substituters by advertised
    priority (cache.nixos.org `40`, all six cachix caches `41`); a run with
    hyprland.cachix listed *first* still queried cache.nixos.org first.

  Verified:
  - The pre-change generated `nix.conf` is byte-identical to the deployed
    `/etc/nix/nix.conf`. The new one differs **only** on the `substituters` line
    (9 → 7 entries) and the `trusted-public-keys` line (8 → 7), with zero
    duplicates, the same normalized cache set and the same key set.
  - Effective query order is identical before and after:
    cache.nixos.org > hyprland > noctalia > claude-code > codex-cli >
    nix-community > yangkx.
  - All six configs evaluate to that same seven-cache list; `cachix.nix` is
    imported unconditionally by `modules/core/default.nix`.
  - `nix flake check` passes; alejandra-clean.

- [x] **15. `auto-optimise-store = true`** — `modules/core/system.nix:5` — **DONE 2026-09-13**

  Prefer `nix.optimise.automatic = true` (a timer) over inline dedup on every
  store write.

  Measured first, so this is a trade rather than a guess. The store is ext4 on
  NVMe (`/dev/nvme0n1p2`, 174 G used), with 554,536 entries in
  `/nix/store/.links`. 190,452 of them are shared by more than one path, so dedup
  saves **9.41 GiB** and should be kept; the question is only *when* it runs.
  Benchmarked with `nix copy --no-check-sigs` of the noctalia closure (925 MiB,
  18,341 files) into throwaway `local?root=` stores on the same disk,
  alternating, with `sync` around each run:

  | `auto-optimise-store` | run 1 | run 2 | run 3 |
  |---|---|---|---|
  | false | 1.61 s (cold cache) | 1.03 s | 1.00 s |
  | true | 1.48 s | 1.50 s | 1.47 s |

  About +48% on warm writes, or roughly 0.5 s per GiB of new store content, paid
  inline on every substitution and build output. The nightly alternative is
  cheap: `nix-store --optimise` skips files already hardlinked into `.links`
  without re-hashing them, so each run only hashes what arrived since the last.

  Resolution: removed `auto-optimise-store = true`, added
  `nix.optimise.automatic = true` with the nixpkgs defaults. They fit a desktop
  that is often off at night: `dates = ["03:45"]`, `persistent = true` (a missed
  run fires at next boot), `randomizedDelaySec = 1800`. The service runs at
  `Nice=19` with idle CPU and IO scheduling and `X-RestartIfChanged=false`, so a
  switch never starts it.

  Verified:
  - Generated `nix.conf` differs on exactly one line:
    `auto-optimise-store = true` → `false`.
  - `nix-optimise.timer` is `OnCalendar=03:45`, `Persistent=true`,
    `RandomizedDelaySec=1800`, `WantedBy=timers.target`. The service is
    `nix-store --optimise` (nix 2.34.8). Both pass `systemd-analyze verify`.
  - The service's `ConditionACPower=true` holds here: `systemd-ac-power` → `yes`.
    The only power supply is the Logitech receiver's `hidpp_battery_0`
    (`scope=Device`), which systemd ignores, so the job won't be skipped.
  - `nix flake check` passes; alejandra-clean.

  Trade-off accepted: paths written during the day stay un-deduplicated until the
  next run, so the store briefly uses a little more space. After switching,
  `systemctl list-timers nix-optimise` should list the timer.

- [x] **16. `openlogi` pins a 42-day-old nixpkgs** — **CLOSED, WON'T DO 2026-09-13** (premise was wrong; no change made)

  The lock carries four distinct nixpkgs revs: ours, hyprland's, noctalia's and
  openlogi's. Hyprland's and noctalia's are deliberate — following them forfeits
  their cachix hits. `openlogi` is our own repo, so
  `inputs.nixpkgs.follows = "nixpkgs"` is free there and removes one full nixpkgs
  evaluation.

  The four-revs part is right: ours `8ce4ef6` (09-10), hyprland `0968519`
  (09-03), noctalia and noctalia-greeter sharing tarball `c043004` (09-05), and
  openlogi `f8e81fc` (08-01). The "free" part is wrong. **openlogi is in exactly
  the same position as hyprland and noctalia**:
  - Its `nixosModules.default` installs `self.packages.<system>.openlogi`, built
    from *openlogi's* nixpkgs plus rust-overlay. Its flake sets
    `nixConfig.extra-substituters = yangkx.cachix.org`, and its `nix.yml` CI
    pushes non-PR builds to Cachix.
  - The deployed `l57ih1vi…-openlogi-0.8.3` was **substituted, not built**
    (`ultimate: false`, signed `yangkx.cachix.org-1:`).
  - With `--override-input openlogi/nixpkgs` set to our rev, the package becomes
    `gvxrhjsv…-openlogi-0.8.3`, which is on neither yangkx.cachix nor
    cache.nixos.org. `nix build --dry-run` reports **234 derivations to build**:
    `rust-minimal-1.98.0` plus a GPUI / wgpu / zbus crate tree. That rebuild
    would recur on every `nix flake update`, because our nixpkgs moves and CI
    only ever builds against openlogi's own lock.

  What following would actually save:
  - **Evaluation: nothing measurable.** `nix eval --no-eval-cache` of the amd
    toplevel took 11.7 / 11.8 / 11.7 s as-is vs 12.2 / 11.8 / 11.5 s with a real
    `follows` + `nix flake lock` (applied temporarily, then both files restored
    from backup). Nixpkgs is lazy, so openlogi only forces a sliver of it. (A
    first attempt via `--override-input` read 14.0 s, but that was the override
    re-locking on each run, not a real cost.)
  - **Closure: ~66 MiB.** 18 of the 19 paths in openlogi's 160.7 MiB runtime
    closure duplicate libraries the system already has from our nixpkgs: 15
    identical versions under another hash (32.2 MiB) and 3 different versions
    (34.2 MiB, mostly a second `glibc-2.42-67`, 33.4 MiB).
  - One fewer nixpkgs source fetched when the lock changes.

  About 66 MiB of disk does not justify a 234-derivation Rust/GPUI build after
  every update, so this stays as-is. To flip it anyway, it's the one-liner
  above; expect `openlogi-0.8.3` to compile locally.

  Why the pin is 42 days old, for fixing it at the source instead (in the
  OpenLogi repo, not this flake): its `.github/workflows/update-flake-lock.yml`
  is gated with `if: github.repository == 'AprilNEA/OpenLogi'`, so on the
  `yangkx1024/OpenLogi` fork the monthly lock refresh never runs. Refreshing the
  fork's lock (by hand, by merging upstream's lock PR, or by changing that
  condition) would narrow the version gap while keeping the Cachix hits.

- [x] **17. `ncg` fights `programs.nh.clean`** — `modules/home/cli/shell.nix:13` vs `modules/core/nh.nix:10` — **DONE 2026-09-13**

  The alias runs `nix-collect-garbage -d` (deletes every old generation) while nh's
  cleaner keeps 3. Pick one policy.

  Context: `ncg` is actively used, with 74 entries in `~/.zsh_history`, so it was
  kept rather than deleted. It was also defeating the safety net: at review time
  there were 20 system generations, and one `ncg` would have left 1, while the
  weekly `nh-clean` keeps 3.

  Compared the two against nh 4.4.2 source (`crates/nh-clean/src/clean.rs`):
  - **Scope matches.** `nh clean all` self-elevates and walks
    `/nix/var/nix/profiles`, `…/per-user/*`, and root's plus uid 1000–1099's
    `~/.local/state/nix/profiles`. That covers both of `ncg`'s
    `nix-collect-garbage` calls, including the Home Manager profile. It then runs
    `nix store gc`.
  - **nh also removes gcroots** for `result` links and direnv environments,
    which `nix-collect-garbage` never did. Checked on this machine: all 23 it
    would delete are dangling `/tmp/nh-os*/result` links from past `nh os` runs,
    so nothing live is lost. The weekly timer has always done this anyway.
  - **nh never touches the bootloader**; there is no `switch-to-configuration` in
    the clean crate. `ncg`'s trailing `switch-to-configuration boot` is still
    needed to drop systemd-boot entries for deleted generations.

  Resolution: `ncg = "nh clean all ${osConfig.programs.nh.clean.extraArgs} && sudo /run/current-system/bin/switch-to-configuration boot"`.
  The retention policy lives only in `modules/core/nh.nix`; the alias reads it
  through `osConfig`, which HM's NixOS integration passes, so the two can't
  drift again. For a one-off aggressive clean, run
  `nh clean all --keep 1` by hand.

  Verified:
  - `nix flake check` passes; alejandra-clean.
  - All six configs evaluate `ncg` to
    `nh clean all --keep 3 && sudo /run/current-system/bin/switch-to-configuration boot`.
    The `nh-clean.service` script is `exec …/nh clean all --keep 3`.
  - Generated `.zshrc` line 77: `alias -- ncg='nh clean all --keep 3 && sudo …'`,
    which zsh parses back to the same string.
  - Single-owner check: overriding `programs.nh.clean.extraArgs` to
    `"--keep 5 --keep-since 7d"` via `extendModules` changed **both** the alias
    and the timer script.
  - Dry run on the live system profile (`nh clean profile … --keep 3 --dry --no-gc`):
    16 DEL, 3 OK (generations 493–495 kept).

  Not run for real: it needs sudo. Also noted: the 2026-08-31 `nh-clean` "failure"
  (`Failed with result 'signal'`) was the persistent timer firing on resume, with
  the power key pressed a second later. Harmless.

- [x] **18. Global QML paths plus loose Qt packages** — `modules/core/qt.nix:7-26` — **DONE 2026-09-13**

  `QML_IMPORT_PATH` / `QML2_IMPORT_PATH` system-wide plus unwrapped `qt6.*` in
  `systemPackages` is the classic workaround for an unwrapped QML app, and it can
  break other Qt apps. Noctalia's own wrapper should handle its imports now — test
  whether this whole module can be deleted.

  Stronger than "noctalia's wrapper handles it": **noctalia 5.1.0 has no Qt at
  all.** Its runtime closure contains no `qtbase`, `qtdeclarative`, `qml` or
  `quickshell` path, and neither does noctalia-greeter 1.5.0's. The module dates
  from the Quickshell/QML era (`ad5c8a7` "Fix qt lib issue", 2026-06-12).

  Who still uses Qt: scanned every binary on `/run/current-system/sw/bin` and
  the user profile for `qtbase` in its closure, checked which ones actually
  create a QML engine (`QQmlApplicationEngine`/`QQuickView`/…), and read
  their wrapper variables:
  - The only QML users are **hyprland-qtutils** (`hyprland-dialog`,
    `-update-screen`, `-donate-screen`), wrapped with nixpkgs'
    `NIXPKGS_QT6_QML_IMPORT_PATH` + `QT_PLUGIN_PATH`.
  - Widgets only, and wrapped: `fcitx5-configtool`/`fcitx5-config-qt`,
    `fcitx5-qt5`/`-qt6`, `qt5ct`, `qt6ct`, `hyprland-share-picker`.
  - All Qt6 users are on 6.11.2, so the global path wasn't breaking anything
    *yet*. The risk was latent: it would bite once a Qt app from another nixpkgs
    rev (e.g. hyprland's) moved to a different Qt minor, or a Qt5 QML app
    resolved imports from the Qt6 dirs in the list.

  Runtime proof, with windows routed to a silent `special:probe` by *title*
  (the first class-based attempt missed `hyprland-dialog`, whose class is
  empty, so it may have flashed on screen), matched by PID, and killed
  afterwards. The "after" run used `env -u QML_IMPORT_PATH` and set
  `QML2_IMPORT_PATH` to only the HM profile dirs, i.e. the post-change
  environment:

  | app | current env | without global QML vars |
  |---|---|---|
  | `hyprland-dialog` (QML) | window 304×200, no QML errors | **window 304×200, no QML errors** |
  | `fcitx5-config-qt` | window, no errors | window, no errors |
  | `qt6ct` | window, no errors | window, no errors |

  Resolution: `qt.nix` loses the two QML variables and all eight `systemPackages`
  entries (`qt6.{qt5compat,qtbase,qtquick3d,qtwayland,qtdeclarative,qtsvg}`,
  `kdePackages.qt5compat`, which is the same derivation as `qt6.qt5compat`, and
  `qt5.qtgraphicaleffects`). A comment says why they shouldn't come back. The
  file is **kept**, holding only `QT_QPA_PLATFORM` and
  `QT_WAYLAND_DISABLE_WINDOWDECORATION`. Those are also set in
  `hyprland/env.nix` but reach systemd user services only through these PAM
  session variables, so choosing their owner is left to **item 20** rather
  than silently changed here.

  Verified:
  - Built both toplevels. The new system's `/etc/set-environment` no longer
    exports `QML_IMPORT_PATH` / `QML2_IMPORT_PATH`. `QT_PLUGIN_PATH` (fcitx5
    im-module), `QT_QPA_PLATFORM` and `QT_WAYLAND_DISABLE_WINDOWDECORATION` are
    unchanged. HM's `QT_QPA_PLATFORMTHEME = qt5ct` is untouched.
  - **Closure: 15.891 → 15.889 GiB, only 1.1 MiB** (`qtgraphicaleffects-5.15.19`
    is the one package that leaves). The qt6 packages stay in the closure because
    fcitx5, hyprland-qtutils and xdph depend on them anyway; the other 14 changed
    paths are rehashed config (`system-path`, `etc`, units). This is an
    environment-hygiene fix, not a disk one.
  - `nix flake check` passes; alejandra-clean (which also fixes this file's half of item 36).

- [x] **19. `eza` options** — `modules/home/cli/eza.nix:11-20` — **DONE 2026-09-13**

  `--git-ignore` means every `ls` hides gitignored files (surprising inside a build
  dir), and `--icons=always` duplicates `icons = "auto"`.

  How the flags reach `ls`: HM's eza module (`modules/programs/eza.nix:133-143`)
  folds `icons`/`git`/`extraOptions` into an alias **named `eza`**, and zsh expands
  aliases recursively, so `ls` → `eza` →
  `eza --icons auto --git … --git-ignore '--icons=always' --classify '--hyperlink=auto'`.

  Both findings confirmed, and the icons one is worse than a duplicate. Tested in
  a scratch git repo shaped like a Gradle/nix project (`build/`,
  `local.properties`, `debug.log`, `.direnv/`, `result` all in `.gitignore`), by
  sourcing the alias lines of the deployed `~/.zshrc` vs the newly generated one
  into `zsh -f`:

  | | old aliases | new aliases |
  |---|---|---|
  | `ls` | `app result settings.gradle.kts` (hides **build, debug.log, local.properties**) | all 6 non-hidden entries |
  | `la` ("list all") | still hides **.direnv, .git, build, debug.log, local.properties** | all 9 entries, same as `ls -A` |
  | `tree` | ignored files hidden | identical entry set (kept on purpose) |
  | `ls . \| od` first bytes | `ee 97 bf 20 61 70 70` = **icon glyph + space** before `app` | `61 70 70` = `app` |

  `--icons=always` comes after HM's `--icons auto`, and eza takes the last
  occurrence, so icons leaked into every pipe (`ls | grep`, `ls > list`,
  `ls | xargs`). With `auto` alone, pipes are clean. HM's two-argument
  `--icons auto` is parsed correctly: `auto` is taken as WHEN, not as a path.
  (`result` shows in every variant; eza doesn't apply gitignore to symlinks.)

  Resolution (`eza.nix`):
  - Removed `--git-ignore` and `--icons=always` from `extraOptions`, with a
    comment saying why.
  - Added `--git-ignore` to the `lt` and `tree` aliases only. Hiding `build/`,
    `.git` and `node_modules` is useful in a tree, and it keeps their current
    behaviour.
  - Dropped redundant alias flags: `ll` `eza  -lh --no-user --long` →
    `eza -l --no-user`, and `la` `eza -lah ` → `eza -la`. In eza `-h` is `--header`,
    already global, and `--long` is `-l`. Byte-compared with forced colour, icons and
    classify: identical output.
  - The fzf previews call `eza --tree … --colour=always` directly from `sh`,
    not through aliases, so they're unaffected.

  Verified: `nix flake check` passes; alejandra-clean. The generated `.zshrc` now
  has `eza='eza --icons auto --git --group-directories-first --no-quotes --header --classify '\''--hyperlink=auto'\'''`.

  Side note for anyone scripting eza: 0.23 reads paths from **stdin** when stdin is
  not a TTY. A bare `eza` with a non-terminal stdin lists nothing (EOF) or blocks
  (open pipe/socket); pass an explicit path. Interactive `ls` is unaffected.

- [x] **20. Env vars declared in three places** — **DONE 2026-09-13**

  `NIXOS_OZONE_WL` in `modules/core/system.nix:35` and
  `modules/home/hyprland/env.nix:5`; `QT_QPA_PLATFORM` and
  `QT_WAYLAND_DISABLE_WINDOWDECORATION` in `modules/core/qt.nix:30-31` and
  `env.nix:12-13`. Pick one owner per variable.

  Also `SDL_VIDEODRIVER = "x11"` (`env.nix:15`) forces all SDL apps off Wayland;
  SDL2/3 handle Wayland fine now.

  **Owner chosen: `modules/home/hyprland/env.nix`** (`hl.env`), where every other
  session toolkit hint already lives (`GDK_BACKEND`, `CLUTTER_BACKEND`,
  `MOZ_ENABLE_WAYLAND`, `ELECTRON_OZONE_PLATFORM_HINT`). Traced the live session
  to check that this one owner reaches everything:
  - Chain: `greetd` → `start-hyprland` → `.Hyprland-wrapped`. `start-hyprland`'s
    environment (before any `hl.env`) already had `NIXOS_OZONE_WL`, from
    `environment.variables` via `/etc/set-environment`
    (`__NIXOS_SET_ENVIRONMENT_DONE=1`), and both `QT_*`, from `sessionVariables`
    via `/etc/pam/environment`. So each was set twice with the same value, and
    `hl.env` alone yields the same child environment; noctalia, a Hyprland child,
    shows all of them.
  - `hyprland.nix` sets `systemd.variables = ["--all"]`, so HM's exec-once runs
    `dbus-update-activation-environment --systemd --all` **before**
    `hyprland-session.target` starts. `systemctl --user show-environment` has all
    the variables, so systemd user units (xdg autostart, openlogi-agent) and D-Bus
    activated services (xdph's Qt share picker) get them without the NixOS copies.
  - Losing the NixOS copies only affects TTY/SSH logins, where none of these
    Wayland hints can apply anyway.

  **`SDL_VIDEODRIVER=x11` was actively rerouting apps.** Installed SDL consumers
  are `ffplay` and the `qemu-system-*` SDL display (libSDL2 via `sdl2-compat` on
  `sdl3-3.4.14`), plus Steam games. Live probe: ffplay test pattern on a silent
  floating `special:probe`:

  | `SDL_VIDEODRIVER` | window | logical size (640×480 video, scale 2) |
  |---|---|---|
  | `x11` (old) | `xwayland=true` | 320×240 |
  | unset (new) | **`xwayland=false`**, native Wayland | 320×240 |
  | `wayland` | `xwayland=false` | — |

  sdl2-compat/SDL3 already defaults to Wayland, so the variable only forced
  XWayland; apparent size is the same either way. Steam games keep whatever their
  runtime picks (Proton renders via Wine/X11 regardless). If a native SDL game
  misbehaves, override it per game with the Steam launch option
  `SDL_VIDEODRIVER=x11 %command%` rather than globally.

  Resolution:
  - `system.nix`: removed `environment.variables.NIXOS_OZONE_WL`.
  - `modules/core/qt.nix`: **deleted** (after item 18 it held only these two
    `QT_*` duplicates), along with its import in `modules/core/default.nix`.
  - `env.nix`: removed `SDL_VIDEODRIVER`, and added a comment that it is the single
    owner and why that suffices.

  Verified:
  - `nix flake check` passes (including with `qt.nix` deleted but not staged);
    alejandra-clean.
  - Built both toplevels. The new `/etc/set-environment` and
    `/etc/pam/environment` contain none of the four variables (before:
    set-environment had 3, pam/environment had 2). The generated `hyprland.lua`
    diff is exactly `- hl.env("SDL_VIDEODRIVER", "x11")`, and the other three
    `hl.env` lines remain.
  - Each variable now has exactly one definition in the repo.

  After switching, the running session keeps the old values until next login.
  Then `systemctl --user show-environment | grep -E 'OZONE|QT_QPA|SDL'` should
  show the three kept vars and no `SDL_VIDEODRIVER`.

  Observed, not changed: `exec-once.nix` adds its own
  `dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP`
  (generated `hyprland.lua:723`), which repeats what HM's systemd integration
  already runs at `:323`. Harmless, but redundant.

- [x] **21. Unexplained `mkForce`s** — **DONE 2026-09-13**

  `modules/home/cli/bat.nix:15` forces the theme to Dracula, opting bat out of
  noctalia's theming while everything else follows Ayu;
  `modules/home/qt.nix:4` forces `qtct`. Both suggest a conflict that deserves a
  one-line comment, or removal if the conflict is gone.

  **The conflict is gone.** Both lines are verbatim from ZaneyOS (`~/zaneyos`
  has the identical `bat.nix` and `qt.nix`), where `modules/core/stylix.nix`
  defined these options. This flake dropped Stylix in `cb5ade7` "Remove stylix
  config", so the forces have overridden nothing since. Confirmed from the module
  system: via
  `options.home-manager.users.valueMeta.attrs.yangkx.configuration.options`,
  `qt.platformTheme` has exactly one definition (`modules/home/qt.nix`), and
  `programs.bat.config` has two, `bat.nix` plus HM's `programs/ghostty.nix`, but
  ghostty's carries no `theme` key.

  Also corrected the premise about bat: there is no noctalia theming to opt out
  of. Noctalia's builtin templates (`assets/templates/`) cover alacritty, btop,
  cava, emacs, foot, ghostty, gtk, helix, hyprland, kde, kitty, labwc, mango,
  niri, qt, scroll, starship, sway, umbriel and wezterm, with **no bat**. So Dracula
  is a plain preference, not an override, and was kept. (For bat to follow the
  noctalia palette, `theme = "ansi"` would take the 16 colours from the
  noctalia-themed ghostty.)

  Resolution: `lib.mkForce "Dracula"` → `"Dracula"` and `lib.mkForce "qtct"` →
  `"qtct"`, and dropped the now-unused `lib` argument from both files. No comment
  added; there is nothing left to explain.

  Verified: `nixosConfigurations.amd` toplevel drv **byte-identical** before and
  after (`ipjxp3pb172f4l260a3r08frxxvnkigg`), so the values are unchanged.
  `nix flake check` passes; alejandra-clean. The only `mkForce` left in the repo
  is inside a commented-out line in `modules/drivers/nvidia-amd-hybrid.nix:29`.

- [x] **22. No `devShells` output** — `flake.nix:66-77` — **DONE 2026-09-13**

  `nix develop` fails; `shell.nix` is only reachable via `nix-shell`.

  Evidence: `nix develop -c true` →
  `error: flake ... does not provide attribute 'devShells.x86_64-linux.default'`

  Fix: one line —
  `devShells.x86_64-linux.default = import ./shell.nix { pkgs = nixpkgs.legacyPackages.x86_64-linux; };`

  Resolution: added exactly that line (plus a one-line comment) after
  `formatter` in `flake.nix`, reusing `shell.nix` so there is one definition for
  both entry points.

  Checked before settling on it:
  - **Formatter drift.** `shell.nix` ships nixpkgs' `alejandra-4.0.0`, while
    `nix fmt` uses the flake input's `alejandra-4.0.0+20260911.33a2874`. Ran both
    over copies of every tracked `.nix` file: **0 files** formatted differently,
    so the dev-shell formatter can't fight `nix fmt`. No need to thread the flake's
    formatter into `shell.nix`.
  - `LD_LIBRARY_PATH = makeLibraryPath [ nixd ]` in `shell.nix` is **redundant**:
    `nixd-2.9.2/bin/nixd` resolves its own `libnixd*.so` via RPATH (`ldd`: 0 not
    found without it). It's harmless because that dir holds only nixd's two libs,
    so it was left alone. Delete it if `shell.nix` is ever touched.

  Verified:
  - `nix develop -c …` builds `nix-shell-env` and puts `nixd-2.9.2`,
    `nil-2026-07-23` and `alejandra-4.0.0` on `PATH`.
  - `nix flake show` lists `devShells.x86_64-linux.default`; `nix flake check`
    now also runs "checking derivation devShells.x86_64-linux.default" and passes.
  - **Same derivation both ways:** `.#devShells.x86_64-linux.default.drvPath` and
    `nix-instantiate shell.nix` are both `f325fvjbprpf3gyhp9ybw7bxv7maqfig-nix-shell.drv`.
    `<nixpkgs>` resolves through the system flake registry to the deployed
    nixpkgs, which equals the lock. After a `nix flake update` they'll differ until
    the next switch, which is expected.
  - `nixosConfigurations.amd` toplevel drv unchanged; alejandra-clean.

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
