{ ... }:
{
  modules.hjem.lazygit = { config, pkgs, theme, ... }:
    let
      settings.gui.theme = with theme.colors; {
        activeBorderColor = [ base0D "bold" ];
        inactiveBorderColor = [ base03 ];
        searchingActiveBorderColor = [ base04 "bold" ];
        optionsTextColor = [ base06 ];
        selectedLineBgColor = [ base03 ];
        cherryPickedCommitBgColor = [ base02 ];
        cherryPickedCommitFgColor = [ base03 ];
        unstagedChangesColor = [ base08 ];
        defaultFgColor = [ base05 ];
      };
      path = if pkgs.stdenv.hostPlatform.isDarwin
        then "Library/Application Support/lazygit/config.yml"
        else ".config/lazygit/config.yml";
    in {
      packages = [ pkgs.lazygit ];
      files.${path}.source = (pkgs.formats.yaml { }).generate "lazygit.yml" settings;
    };
}
