{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.fastfetch = {
    enable = true;
    package = pkgs.fastfetch;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

      logo = {
        source = "./assets/hokusai.png";
        type = "kitty-direct";
        width = 10;
        height = 10;
        padding = {
          top = 1;
          left = 3;
        };
      };

      display = {
        separator = "  ";
        constants = [
          "─────────────────"
        ];
        key = {
          type = "icon";
          paddingLeft = 2;
        };
      };

      modules = [
        {
          type = "custom";
          format = "┌{$1} {#1}Hardware Information{#} {$1}┐";
        }
        "host"
        "cpu"
        "gpu"
        "disk"
        "memory"
        "brightness"
        "battery"
        {
          type = "custom";
          format = "├{$1} {#1}Software Information{#} {$1}┤";
        }
        {
          type = "title";
          keyIcon = "";
          key = "Title";
          format = "{user-name}@{host-name}";
        }
        "os"
        "kernel"
        "de"
        "wm"
        "terminal"
        "packages"
        "uptime"
        {
          type = "custom";
          format = "└{$1}──────────────────────{$1}┘";
        }
        {
          type = "colors";
          paddingLeft = 2;
          symbol = "circle";
        }
      ];
    };
  };
}
