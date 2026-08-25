{inputs, ...}: {
  nixpkgs.overlays = [
    # Provide package overlay here
    inputs.claude-code.overlays.default
    inputs.codex-cli-nix.overlays.default

    # dwarfs 0.14.0 vendors folly + fbthrift, which don't compile against
    # fmt 12.2.0 (missing <cstring> in folly, deprecated fmt::join in fbthrift).
    # 0.15.x drops both dependencies entirely. This mirrors the pending nixpkgs
    # bump and self-disables once that lands:
    # https://github.com/NixOS/nixpkgs/pull/549694
    (final: prev: {
      dwarfs =
        if prev.lib.versionAtLeast prev.dwarfs.version "0.15.6"
        then prev.dwarfs
        else
          prev.dwarfs.overrideAttrs (old: {
            version = "0.15.6";
            src = prev.fetchFromGitHub {
              owner = "mhx";
              repo = "dwarfs";
              tag = "v0.15.6";
              fetchSubmodules = true;
              hash = "sha256-Nq7H/qm58j77YmYmlkEhU8Hfh59Z2+Vj+4apn31HHHc=";
            };
            env =
              old.env
              // {
                GTEST_FILTER =
                  "-"
                  + prev.lib.concatStringsSep ":" [
                    "dwarfs/tools_test.end_to_end/*"
                    "dwarfs/tools_test.mutating_and_error_ops/*"
                    "dwarfs/tools_test.categorize/*"
                    # Require a working FUSE device and fusermount3, unavailable in sandbox.
                    "dwarfs/fuse_driver_test*"
                    "tools_test.dwarfs_obsolete_options*"
                    "sparse_files_test.random_large_files*"
                    "sparse_files_test.random_small_files_fuse*"
                    "sparse_files_test.huge_holes_fuse*"
                    # Requires xattr support unavailable in sandbox.
                    "xattr_test.portable_xattr"
                  ];
              };
          });
    })
  ];
}
