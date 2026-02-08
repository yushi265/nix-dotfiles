{ config, pkgs, machineType, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage
  home = {
    username = "shina";
    homeDirectory = "/Users/shina";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    stateVersion = "24.11";
  };

  # Packages to install
  home.packages = with pkgs; [
    # Packages will be added in Phase 2
  ];

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
