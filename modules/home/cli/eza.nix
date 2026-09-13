# Eza is a ls replacement
_: {
  programs.eza = {
    enable = true;
    icons = "auto";
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    git = true;

    extraOptions = [
      "--group-directories-first"
      "--no-quotes"
      "--header" # Show header row
      # No --git-ignore here: it made `ls`/`la` hide build/, .direnv, .git and
      # other ignored files. The tree aliases below opt into it instead. And no
      # --icons=always: it overrode `icons = "auto"` and leaked glyphs into pipes.
      # "--time-style=long-iso" # ISO 8601 extended format for time
      "--classify" # append indicator (/, *, =, @, |)
      "--hyperlink=auto" # make paths clickable in some terminals
    ];
  };
  # Aliases to make `ls`, `ll`, `la` use eza
  home.shellAliases = {
    ls = "eza";
    lt = "eza --tree --level=2 --git-ignore";
    ll = "eza -l --no-user";
    la = "eza -la";
    tree = "eza --tree --git-ignore";
  };
}
