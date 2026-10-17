{ inputs, ... }:
{
  modules.nixos.typst = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      typst
      typstyle
      typst-live
      tinymist
      tetex
    ];
  };
  modules.darwin.typst =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        typst
        typstyle
        typst-live
        tinymist
        tetex
      ];
    };
}
