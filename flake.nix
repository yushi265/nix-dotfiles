{
  description = "shina's nix-darwin + home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }: let
    # Helper function to create darwin system
    mkDarwinSystem = { hostname, username, system ? "aarch64-darwin" }: let
      # Derive machineType from hostname
      # "MacBook-Pro" or "MacBook-Pro.local" -> "personal"
      # anything else -> "work"
      machineType = if nixpkgs.lib.hasInfix "MacBook-Pro" hostname
                    then "personal"
                    else "work";
    in nix-darwin.lib.darwinSystem {
      inherit system;

      specialArgs = {
        inherit machineType username;
      };

      modules = [
        ./hosts/common.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${username} = import ./home.nix;
          home-manager.extraSpecialArgs = { inherit machineType; };
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
  in {
    # System configuration
    darwinConfigurations = {
      "MacBook-Pro" = mkDarwinSystem {
        hostname = "MacBook-Pro";
        username = "shina";
      };

      "MacBook-Pro---old" = mkDarwinSystem {
        hostname = "MacBook-Pro---old";
        username = "shina";
      };

      # Private machine configuration
      "private" = mkDarwinSystem {
        hostname = "MacBook-Pro";
        username = "shiina";
      };
    };

    # For nix-darwin commands
    darwinPackages = self.darwinConfigurations."MacBook-Pro".pkgs;
  };
}
