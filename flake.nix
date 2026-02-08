{
  description = "shina's nix-darwin + home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, ... }: let
    # Helper function to create darwin system
    mkDarwinSystem = { hostname, system ? "aarch64-darwin" }: let
      # Derive machineType from hostname
      # "MacBook-Pro" or "MacBook-Pro.local" -> "personal"
      # anything else -> "work"
      machineType = if nixpkgs.lib.hasInfix "MacBook-Pro" hostname
                    then "personal"
                    else "work";
    in nix-darwin.lib.darwinSystem {
      inherit system;

      specialArgs = {
        inherit machineType;
      };

      modules = [
        ./hosts/common.nix
      ];
    };
  in {
    # System configuration
    darwinConfigurations = {
      "MacBook-Pro" = mkDarwinSystem {
        hostname = "MacBook-Pro";
      };
    };

    # For nix-darwin commands
    darwinPackages = self.darwinConfigurations."MacBook-Pro".pkgs;
  };
}
