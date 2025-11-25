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
    # Keep defaults; set agent behavior for all hosts
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      identityFile = [ "~/.ssh/id_ed25519" ];
      identitiesOnly = true;
    };
  };

  services.ssh-agent.enable = true;
}
