{ ... }:

{
  # Using Determinate Systems installer, so let it manage Nix
  nix.enable = false;

  imports = [
    ../modules/darwin/packages.nix
    ../modules/darwin/zsh.nix
    ../modules/darwin/homebrew.nix
    ../modules/darwin/system.nix
  ];
}
