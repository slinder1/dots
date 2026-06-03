{
  lib,
  pkgs,
  self',
  ...
}:
{
  home.packages = with self'.package-lists; lib.concatLists [
    core
  ];
}
