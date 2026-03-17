{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  system = {
    primaryUser = "scott";
    stateVersion = 6;

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
      };
      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        AppleShowAllFiles = true;
        QuitMenuItem = true;
        ShowPathbar = true;
        FXRemoveOldTrashItems = true;
      };
      NSGlobalDomain."com.apple.swipescrolldirection" = false;
    };

    # https://github.com/ryan4yin/nix-darwin-kickstarter/blob/f79b4d4cbd9c8c2ea56b6e5016131ff2179d3775/minimal/modules/system.nix#L14-L19
    activationScripts.postActivation.text = ''
      killall Dock
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };
}
