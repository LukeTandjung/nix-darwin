{ ... }:
{
  modules.hjem.zsh = { config, pkgs, ... }: {
    packages = [ pkgs.zsh pkgs.nix-zsh-completions ];
    files = {
      ".zshenv".text = ''
        source ${config.environment.loadEnv}
      '' + config.zshEnv;
      ".zprofile".text = "";
      ".zshrc".text = ''
        path=("$HOME/.cargo/bin" "/etc/profiles/per-user/${config.user}/bin" ''${path:#$HOME/.cargo/bin})
        path=(''${path:#$HOME/.local/bin} "$HOME/.local/bin")
        export PATH
        fpath=("/etc/profiles/per-user/${config.user}/share/zsh/site-functions" $fpath)
        typeset -U path cdpath fpath manpath
        autoload -Uz compinit
        compinit
        HISTFILE="$HOME/.zsh_history"
        HISTSIZE=10000
        SAVEHIST=10000
        setopt HIST_IGNORE_DUPS SHARE_HISTORY
      '' + config.zshInit;
    };
  };
}
