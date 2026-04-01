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
  imports = lib.optional (builtins.pathExists ~/.config/home.nix) ~/.config/home.nix;
  programs.home-manager.enable = true;
  home.packages = with self'.package-lists; lib.concatLists [
    utils
  ];
  home.username = username;
  home.homeDirectory = ~/.;
  home.stateVersion = "25.11";
}
