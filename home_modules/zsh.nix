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
      path=(
        $HOME/.cargo/bin
        ${lib.optionalString pkgs.stdenv.isDarwin "/opt/homebrew/bin"}
        ''${path:#$HOME/.cargo/bin}
      )
      path=(''${path:#$HOME/.local/bin} $HOME/.local/bin)
      export PATH
    '';
  };
}
