{ ... }:

{
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

  imports = [
    ./modules/home/git.nix
    ./modules/home/secrets.nix
    ./modules/home/files.nix
    ./modules/home/vscode.nix
    ./modules/home/activation.nix
  ];
}
