{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    nixd # nix lsp
    alejandra # nix formatter
  ];

  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
    pkgs.nixd
  ];
}
