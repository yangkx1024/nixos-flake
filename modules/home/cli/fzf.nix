# Fzf is a general-purpose command-line fuzzy finder.
{...}: let
  # Ctrl-T's walker yields directories as well as files, so the preview has to
  # cope with both - bat on a directory just prints an error into the pane.
  # Kept in one place because the `fe` alias below previews the same way.
  # Note every option list here is space-joined into a single env var by
  # home-manager (sessionVariables = mapAttrs toString) and re-split by fzf, so
  # any value containing a space needs its own quotes inside the Nix string.
  preview = "'[ -d {} ] && eza --tree --level=2 --colour=always {} || bat --style=numbers --color=always --line-range :500 {}'";
  previewWindow = "right:60%:wrap";
in {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # FZF_DEFAULT_OPTS is inherited by *every* fzf invocation: the Ctrl-R history
    # widget, the Ctrl-T file widget, Alt-C, and third parties like zoxide's
    # `cdi`. fzf's key-bindings.zsh concatenates it ahead of each widget's own
    # options (__fzf_defaults), and none of the widgets rebind enter or override
    # --preview, so whatever lands here leaks into all of them.
    #
    # Appearance only, therefore. This list used to also carry
    #   --bind='enter:execute(nvim {})'
    #   --preview='bat ... {}'
    # which meant Ctrl-R opened nvim on the selected *history line* and returned
    # an empty selection to the widget, so nothing was ever inserted at the
    # prompt, and the preview pane ran bat against the command text. The
    # file-picking behaviour those two were after now lives in fileWidget and in
    # the `fe` alias below.
    defaultOptions = [
      "--margin=1"
      "--layout=reverse"
      "--border=none"
      "--info=hidden"
      "--prompt='/ '"
      "-i"
      "--no-bold"
    ];

    # Ctrl-T - insert the selected path(s) on the command line. Input lines are
    # paths here, so previewing them is meaningful. enter has to stay `accept`
    # or the widget receives nothing.
    fileWidget.options = [
      "--preview=${preview}"
      "--preview-window=${previewWindow}"
    ];

    # Alt-C - cd into the selected directory.
    changeDirWidget.options = [
      "--preview='eza --tree --level=2 --colour=always {}'"
      "--preview-window=${previewWindow}"
    ];
  };

  # The "fuzzy-pick a file and open it in nvim" flow that the global enter
  # binding was reaching for, as its own command instead of a side effect on
  # every picker. --print0/-0 keeps names with spaces intact, -r makes an empty
  # selection a no-op rather than opening a buffer called "", and -o hands nvim
  # the terminal. --multi so several files can be opened at once.
  home.shellAliases.fe = "fzf --multi --print0 --preview=${preview} --preview-window=${previewWindow} | xargs -0 -r -o nvim";
}
