{ lib, user, ... }:
{
  # FIXME: we benefit from the purity of flakes and the lock file, but the
  # ergonomics around referring to $HOME and having local tweaks outside of git
  # are just sort of awful.
  #
  # So, for any evaluation which reaches this module (namely, home-manager
  # builds) we just require --impure.
  imports = (lib.optional (builtins.pathExists ~/.config/home.nix) ~/.config/home.nix);
  home.username = user;
  home.homeDirectory = ~/.;
  home.stateVersion = "25.11";
}
