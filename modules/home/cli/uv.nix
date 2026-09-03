_: {
  # Python package / project manager.
  # Tools listed here are installed / upgraded by `uv tool` on activation.
  # Their binaries are prebuilt and dynamically linked against an FHS loader,
  # so they need programs.nix-ld (see modules/core/nix-ld.nix) to run on NixOS.
  # `uv tool` links executables into ~/.local/bin, which shell.nix puts on PATH.
  programs.uv = {
    enable = true;
    tool.packages = [
      "nmem-cli" # CLI / TUI for Nowledge Mem
    ];
  };
}
