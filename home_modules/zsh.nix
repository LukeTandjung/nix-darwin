{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    package = pkgs.zsh;
    initContent = ''
      export PATH="$HOME/.cargo/bin:$PATH"
    '';
  };
}
