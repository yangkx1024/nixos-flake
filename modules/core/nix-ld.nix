{pkgs, ...}: {
  # Runs unpatched dynamically linked binaries (uv-managed Python interpreters,
  # PyPI wheels with compiled extensions, ...) by providing an FHS-style loader.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib # libstdc++ for compiled wheels
      zlib
      openssl
      libffi
      bzip2
      xz
      sqlite
      ncurses
      readline
    ];
  };
}
