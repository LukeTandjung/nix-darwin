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
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      identityFile = [ "~/secrets/id_ed25519" ];
      identitiesOnly = true;
    };
  };

  services.ssh-agent.enable = true;
}
