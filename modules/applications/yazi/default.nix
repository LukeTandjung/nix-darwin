{ inputs, ... }:
{
  modules.hjem.yazi =
    {
      config,
      pkgs,
      lib,
      theme,
      ...
    }:
    {
      packages = [ pkgs.yazi ];
      zshInit = ''
        function yy() {
          local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
          yazi "$@" --cwd-file="$tmp"
          IFS= read -r cwd < "$tmp"
          [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
          rm -f -- "$tmp"
        }
      '';
      xdg.config.files = {
        "yazi/theme.toml".text = theme.render ./theme.toml.mustache {
          syntect-theme = toString (pkgs.writeText "kanagawa.tmTheme" (theme.render ./syntax.tmTheme.mustache { }));
        };
        "yazi/yazi.toml".source = (pkgs.formats.toml { }).generate "yazi.toml" {
          mgr = {
            ratio = [
              1
              1
              1
            ];
            show_hidden = true;
          };
          opener = {
            edit = [
              {
                run = ''sudo hx "$@"'';
                desc = "Helix";
                block = true;
                for = "macos";
              }
              {
                run = ''hx "$@"'';
                desc = "Helix";
                block = true;
                for = "linux";
              }
            ];
          };
        };
      };
    };
}
