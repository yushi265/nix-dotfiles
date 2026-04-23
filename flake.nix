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

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "nix-darwin";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, agenix, ... }: let
    # Helper function to create darwin system
    mkDarwinSystem = { configName, hostname, username, system ? "aarch64-darwin" }: let
      # Derive machineType from hostname
      # "MacBook-Pro" or "MacBook-Pro.local" -> "personal"
      # anything else -> "work"
      machineType = if nixpkgs.lib.hasInfix "MacBook-Pro" hostname
                       || hostname == "mbp-m1"
                    then "personal"
                    else "work";
    in nix-darwin.lib.darwinSystem {
      inherit system;

      specialArgs = {
        inherit machineType username configName;
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
          home-manager.sharedModules = [ agenix.homeManagerModules.default ];
        }
      ];
    };
  in {
    # System configuration
    darwinConfigurations = {
      "personal" = mkDarwinSystem {
        configName = "personal";
        hostname = "MacBook-Pro";
        username = "shiina";
      };

      "mbp-m1" = mkDarwinSystem {
        configName = "personal";
        hostname = "mbp-m1";
        username = "shina";
      };
    };

    # For nix-darwin commands
    darwinPackages = self.darwinConfigurations."mbp-m1".pkgs;
  };
}
