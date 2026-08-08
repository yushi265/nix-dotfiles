{ pkgs, lib, machineType, ... }:

{
  home.stateVersion = "24.11";

  # PATH は ~/.zshenv (chezmoi) で管理している。
  # home.sessionPath は programs.zsh を有効にしていないため実際には
  # PATH に反映されず、二重管理になるので置かない。

  programs.home-manager.enable = true;
}
