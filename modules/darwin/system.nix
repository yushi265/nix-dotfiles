{ username, ... }:

{
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  system.primaryUser = username;

  system = {
    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        tilesize = 48;
      };

      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        _FXShowPosixPathInTitle = true;
      };

      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
    };

    stateVersion = 5;
    configurationRevision = null;
  };
}
