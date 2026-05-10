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
      defaultModel = "gpt-5.5";
      defaultThinkingLevel = "low";
      theme = "dark";
      npmCommand = [
        "${pkgs.nodejs}/bin/npm"
        "--prefix"
        "${config.home.homeDirectory}/.pi/npm-global"
      ];
      packages = [
        "npm:pi-web-access"
        "npm:@feniix/pi-notion"
      ];
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
