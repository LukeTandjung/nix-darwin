{ ... }:
{
  modules.hjem.mpvpaper = { pkgs, lib, osConfig, ... }: {
    packages = lib.optional (osConfig.networking.hostName == "Lukes-Um790") pkgs.mpvpaper;
  };
}
