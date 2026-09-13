{
  config,
  vars,
  ...
}: let
  inherit (vars) gitUsername gitEmail;

  # noctalia's community "lazygit" template renders a gui.theme block here. Its
  # apply hook splices that into config.yml, which can't work with a read-only
  # store symlink, so layer the file on top with LG_CONFIG_FILE instead (later
  # files override earlier ones). lazygit refuses to start if a listed file is
  # missing, hence the guard for the window before noctalia's first render.
  lazygitDir = "${config.xdg.configHome}/lazygit";
  loadLazygitTheme = ''
    if [ -r "${lazygitDir}/themes/noctalia.yml" ]; then
      export LG_CONFIG_FILE="${lazygitDir}/config.yml,${lazygitDir}/themes/noctalia.yml"
    fi
  '';
in {
  programs.git = {
    enable = true;
    signing.format = null;

    settings = {
      user = {
        name = "${gitUsername}";
        email = "${gitEmail}";
      };

      # FOSS-friendly settings
      push.default = "simple"; # Match modern push behavior
      credential.helper = "cache --timeout=7200";
      init.defaultBranch = "main"; # Set default new branches to 'main'
      log.decorate = "full"; # Show branch/tag info in git log
      log.date = "iso"; # ISO 8601 date format
      # Conflict resolution style for readable diffs
      merge.conflictStyle = "diff3";

      # Optional: FOSS-friendly Git aliases
      alias = {
        br = "branch --sort=-committerdate";
        co = "checkout";
        df = "diff";
        com = "commit -a";
        gs = "stash";
        gp = "pull";
        lg = "log --graph --pretty=format:'%Cred%h%Creset - %C(yellow)%d%Creset %s %C(green)(%cr)%C(bold blue) <%an>%Creset' --abbrev-commit";
        st = "status";
      };
    };
  };
  programs.lazygit = {
    enable = true;
    settings = {
      git.commit.signOff = true; # Sign off commits by default (git commit -s)
    };
  };
  programs.zsh.initContent = loadLazygitTheme;
  programs.bash.initExtra = loadLazygitTheme;
}
