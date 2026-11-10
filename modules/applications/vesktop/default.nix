{ inputs, ... }:
{
  modules.hjem.vesktop = { pkgs, theme, ... }:
    let
      base = if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support/vesktop" else ".config/vesktop";
      vesktop = pkgs.vesktop.override {
        withSystemVencord = true;
        vencord = inputs.nixpkgs-vesktop.legacyPackages.${pkgs.stdenv.hostPlatform.system}.vencord;
      };
    in {
      packages = [ vesktop ];
      files = {
        "${base}/themes/stylix.css".text = theme.render ./theme.css.mustache {
          font-family = theme.font;
        };
        "${base}/settings/settings.json".text = builtins.toJSON {
          enabledThemes = [ "stylix.css" ];
        };
      };
    };
}
