{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.pi = {
    enable = true;
    settings = {
      defaultProvider = "openai-codex";
      defaultModel = "gpt-5.4";
      defaultThinkingLevel = "medium";
      theme = "dark";
      npmCommand = [
        "${pkgs.nodejs}/bin/npm"
        "--prefix"
        "${config.home.homeDirectory}/.pi/npm-global"
      ];
      packages = [ "npm:pi-web-access" ];
      compaction = {
        enabled = true;
        keepRecentTokens = true;
      };
      retry = {
        enabled = true;
        maxRetries = 3;
      };
    };
  };
}
