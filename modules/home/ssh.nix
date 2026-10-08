{...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      # github.com:22 hangs on this network; GitHub also serves SSH on 443.
      "github.com" = {
        HostName = "ssh.github.com";
        Port = 443;
        User = "git";
        # YubiKey-backed key; don't fall back to other keys.
        IdentityFile = "~/.ssh/id_ed25519_sk";
        IdentitiesOnly = "yes";
      };
    };
  };
}
