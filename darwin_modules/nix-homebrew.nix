{ inputs, config, ... }:
{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "luketandjung";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "FelixKratz/homebrew-formulae" = inputs.homebrew-formulae;
    };
    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [
      "gdal"
      "sketchybar"
    ];
    casks = [
      "figma"
      "capcut"
      "yaak"
      "claude"
      "font-jetbrains-mono-nerd-font"
    ];
  };
}
