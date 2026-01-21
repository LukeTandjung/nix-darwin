{ inputs, config, ... }:
{
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
    taps = builtins.attrNames config.nix-homebrew.taps ++ [
      "FelixKratz/formulae"
    ];
    brews = [
      "sketchybar"
    ];
    casks = [
      "figma"
      "capcut"
      "yaak"
      "claude"
    ];
  };
}
