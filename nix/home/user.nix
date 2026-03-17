{
  lib,
  pkgs,
  self,
  self',
  config,
  inputs,
  inputs',
  username,
  ...
}:
let
  pkgs' = self'.packages;
in
{
  programs.home-manager.enable = true;
  home.packages = with self'.package-lists; lib.concatLists [
    utils
  ];
  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "25.11";
}
