{ pkgs, lib, machineType, ... }:

{
  home.stateVersion = "24.11";

  home.sessionPath = [ "$HOME/.npm-global/bin" ];

  programs.home-manager.enable = true;
}
