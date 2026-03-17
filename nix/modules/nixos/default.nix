{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  users.users.scott = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
