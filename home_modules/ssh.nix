{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # Set agent behavior for all hosts
    settings."*" = {
      AddKeysToAgent = "yes";
      IdentityFile = [ "~/secrets/id_ed25519" ];
      IdentitiesOnly = true;
    };
  };

  services.ssh-agent.enable = true;
}
