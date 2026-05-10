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
