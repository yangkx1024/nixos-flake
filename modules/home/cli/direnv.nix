_: {
  # Per-directory environments from .envrc. nix-direnv caches `use flake` /
  # `use nix` results and pins them as GC roots, so entering a project is
  # instant and `nix-collect-garbage` won't wipe its dev shell.
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
    config.global = {
      hide_env_diff = true; # Skip the long "+VAR -VAR" list on every cd
      warn_timeout = "30s"; # First `use flake` build can take a while
    };
  };

  # direnv's cache dir (holds nix-direnv's profile links) never belongs in a repo.
  programs.git.ignores = [".direnv/"];
}
