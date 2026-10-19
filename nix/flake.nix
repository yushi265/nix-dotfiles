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
    # machineType ("personal" / "work") is declared per configuration below
    mkDarwinSystem = { machineType, username, system ? "aarch64-darwin" }:
      nix-darwin.lib.darwinSystem {
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
      "personal" = mkDarwinSystem {
        machineType = "personal";
        username = "shiina";
      };

      "mbp-m1" = mkDarwinSystem {
        machineType = "personal";
        username = "shina";
      };
    };

    # For nix-darwin commands
    darwinPackages = self.darwinConfigurations."mbp-m1".pkgs;
  };
}
