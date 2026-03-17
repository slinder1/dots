{
  lib,
  self,
  self',
  config,
  inputs,
  inputs',
  ...
}:
{
  home-manager = {
    verbose = true;
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit
        self
        self'
        inputs
        inputs'
        ;
    };
    users.${username} = ./user.nix;
    sharedModules = [ { home.stateVersion = "25.11"; } ];
  };
}
