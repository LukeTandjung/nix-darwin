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
    addKeysToAgent = "yes";
  };

  services.ssh-agent.enable = true;
}
