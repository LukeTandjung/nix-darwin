{ inputs, config, ... }:
{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "luketandjung";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "mocki-toki/homebrew-formulae" = inputs.homebrew-formulae;
    };
    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [
      # Agent tools
      "ast-grep"
      "fastmod"
      "fzf"
      "gh"
      "jq"
      "ripgrep"
      "tree"
      "mkcert"

      "bash"
      "coreutils"
      "gdal"
    ];
    casks = [
      "capcut"
      "claude"
      "figma"
      "font-jetbrains-mono-nerd-font"
      "tailscale-app"
      "yaak"
      "mocki-toki/formulae/barik"
    ];
  };
}
