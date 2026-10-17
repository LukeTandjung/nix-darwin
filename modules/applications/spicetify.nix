{ inputs, ... }:
{
  modules.home.spicetify =
    {
      ...
    }:
    {
      programs.spicetify = {
        enable = true;
      };
    };
}
