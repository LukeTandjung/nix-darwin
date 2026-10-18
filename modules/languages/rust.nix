{ ... }:
{
  modules.nixos.rust = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      rustc
      cargo
      rust-analyzer
    ];
  };

  modules.darwin.rust = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      rustc
      cargo
    ];
  };
}
