{ inputs, ... }:
{
  modules.hjem.spicetify = { pkgs, theme, ... }: {
    imports = [ inputs.spicetify-nix.hjemModules.default ];
    programs.spicetify = {
      enable = true;
      theme = {
        name = "kanagawa";
        src = pkgs.writeTextFile {
          name = "kanagawa-spicetify";
          destination = "/color.ini";
          text = with theme.palette; ''
            [base]
            text = ${base05}
            subtext = ${base05}
            main = ${base00}
            main-elevated = ${base02}
            highlight = ${base02}
            highlight-elevated = ${base03}
            sidebar = ${base01}
            player = ${base04}
            card = ${base03}
            shadow = ${base00}
            selected-row = ${base04}
            button = ${base04}
            button-active = ${base04}
            button-disabled = ${base03}
            tab-active = ${base02}
            notification = ${base02}
            notification-error = ${base08}
            equalizer = ${base0B}
            misc = ${base02}
          '';
        };
        sidebarConfig = false;
      };
      colorScheme = "base";
    };
  };
}
