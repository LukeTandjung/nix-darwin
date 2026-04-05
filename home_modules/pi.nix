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
