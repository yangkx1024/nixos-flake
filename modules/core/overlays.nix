{inputs, ...}: {
  nixpkgs.overlays = [
    # Provide package overlay here
    inputs.claude-code.overlays.default
    inputs.codex-cli-nix.overlays.default
  ];
}
