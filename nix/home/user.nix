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
{
  imports = lib.optional (builtins.pathExists ~/.config/home.nix) ~/.config/home.nix;
  programs.home-manager.enable = true;
  home.username = username;
  home.homeDirectory = ~/.;
  home.stateVersion = "25.11";
}
