{ inputs, ... }:
{
  modules.home.herdr = { ... }: {
    programs.herdr.enable = true;
  };
}
