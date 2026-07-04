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
      export PATH="${lib.optionalString pkgs.stdenv.isDarwin "/opt/homebrew/bin:"}$HOME/.cargo/bin:$PATH:$HOME/.local/bin"
    '';
  };
}
