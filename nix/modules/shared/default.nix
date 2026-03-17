{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.package = pkgs.lixPackageSets.stable.lix;
  users.users = lib.genAttrs [ "root" "scott" ] (user: {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzjrxXfaMwKx9JrWQ3hK6fZt5z4H8xEbNH55irA56jD"
    ];
  });
}
