{
  lib,
  pkgs,
  self',
  homeModules,
  ...
}:
{
  imports = with homeModules; [
    core
  ];
}
