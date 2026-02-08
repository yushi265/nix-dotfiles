{ pkgs, machineType, ... }:

{
  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # Optimize store on each build
      auto-optimise-store = true;
    };

    # Auto garbage collection
    gc = {
      automatic = true;
      interval = { Weekday = 7; };
      options = "--delete-older-than 30d";
    };
  };

  # macOS system packages
  environment.systemPackages = with pkgs; [
    vim
  ];

  # Homebrew integration for GUI apps
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    # GUI applications
    casks = [
      "ghostty"
    ];
  };

  # macOS system settings
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
  };

  # Auto upgrade nix package and the daemon service
  services.nix-daemon.enable = true;

  # Used for backwards compatibility
  system.configurationRevision = null;
}
