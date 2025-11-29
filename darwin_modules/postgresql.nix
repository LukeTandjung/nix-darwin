{ pkgs, system, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    extraPlugins = with pkgs.postgresql17Packages; [
      timescaledb
    ];
    settings.shared_preload_libraries = "timescaledb";
    port = 5432;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';
  };
}
