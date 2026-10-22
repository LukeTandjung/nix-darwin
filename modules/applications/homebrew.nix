{ inputs, ... }:
{
  modules.darwin.homebrew =
    { config, ... }:
    {
      imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        user = "luketandjung";
        taps = {
          "homebrew/homebrew-core" = inputs.homebrew-core;
          "homebrew/homebrew-cask" = inputs.homebrew-cask;
        };
        mutableTaps = false;
      };

      homebrew = {
        enable = true;
        taps = builtins.attrNames config.nix-homebrew.taps;
        # Cross-platform CLI tools are owned by modules/agents/tools/cli/default.nix.
        brews = [ ];
        casks = [
          "bartender"
          "capcut"
          "chatgpt"
          "claude"
          "figma"
          "font-jetbrains-mono-nerd-font"
          "linear"
          "ngrok"
          "postico"
          "tailscale-app"
          "yaak"
        ];
      };
    };
}
