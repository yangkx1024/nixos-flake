{inputs, ...}: {
  imports = [inputs.noctalia-greeter.nixosModules.default];

  programs.noctalia-greeter = {
    enable = true;
    # greeter-args left at default "" → session picker, remembers last choice.
  };
}
