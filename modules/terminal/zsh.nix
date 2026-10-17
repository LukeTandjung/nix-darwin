{ inputs, ... }:
{
  modules.home.zsh =
    {
      config,
      pkgs,
      ...
    }:
    {
      programs.zsh = {
        enable = true;
        package = pkgs.zsh;
        initContent = ''
          path=(
            $HOME/.cargo/bin
            ${config.home.profileDirectory}/bin
            ''${path:#$HOME/.cargo/bin}
          )
          path=(''${path:#$HOME/.local/bin} $HOME/.local/bin)
          export PATH
        '';
      };
    };
}
