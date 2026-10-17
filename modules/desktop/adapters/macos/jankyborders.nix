{ inputs, ... }:
{
  modules.darwin.jankyborders = { ... }: {
    services.jankyborders.enable = true;
  };
}
