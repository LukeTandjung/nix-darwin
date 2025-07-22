
{ pkgs, ... }:

{
  # 1) Core engine settings
  stylix.enable = true;
  stylix.autoEnable = true;
  
  # 2) Inline Base16 “Bauh Nord” scheme
  stylix.base16Scheme = {
    slug   = "bauh-nord";
    scheme = "Bauh Nord";
    author = "Luke Tandjung";
    base00 = "242D42";  base01 = "374057";  base02 = "434C5E";
    base03 = "4C566A";  base04 = "828282";  base05 = "B7B7B7";
    base06 = "EEEEEE";  base07 = "8FBCBB";  base08 = "BF616A";
    base09 = "D08770";  base0A = "EBCB8B";  base0B = "A3BE8C";
    base0C = "88C0D0";  base0D = "81A1C1";  base0E = "B48EAD";
    base0F = "5E81AC";
  };

  # 3) Fonts
  stylix.fonts = {
    monospace = { package = pkgs.jetbrains-mono; name = "JetBrains Mono"; };
    sansSerif = { package = pkgs.jetbrains-mono; name = "JetBrains Mono"; };
    serif = { package = pkgs.jetbrains-mono; name = "JetBrains Mono"; };
    emoji = { package = pkgs.font-awesome; name = "Font Awesome"; };

    sizes = {
      applications = 14;
      desktop = 12;
      popups = 12;
      terminal = 14;
    };
   };

  # 4) Now these will be valid because stylix.nixosModules.stylix was already imported
 }
