{ ... }:
{
  modules.nixos.ssh = {
    # Use the single Home Manager agent below, not competing session agents.
    programs.ssh.startAgent = false;
    services.gnome.gcr-ssh-agent.enable = false;
  };

  modules.home.ssh = { pkgs, ... }: {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        # KeePassXC loads database key attachments into the running agent.
        # Do not read a private key from ~/secrets or the default identity files.
        IdentityFile = [ "none" ];
        IdentitiesOnly = false;
        AddKeysToAgent = "no";
      };
    };

    # macOS already supplies a launchd-managed OpenSSH agent. Keeping its
    # SSH_AUTH_SOCK lets the GUI and terminal use the same agent.
    services.ssh-agent = {
      enable = pkgs.stdenv.hostPlatform.isLinux;
      socket = "ssh-agent";
    };
  };
}
