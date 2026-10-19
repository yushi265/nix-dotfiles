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
    # 構成名は hostname と揃える (~/.zshrc の rebuild() が hostname で引く)
    mkDarwinSystem = { username, system ? "aarch64-darwin" }:
      nix-darwin.lib.darwinSystem {
        inherit system;

        specialArgs = {
          inherit username;
        };

        modules = [
          ./hosts/common.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home.nix;
            home-manager.backupFileExtension = "backup";
          }
        ];
      };
  in {
    # System configuration
    darwinConfigurations = {
      "mbp-m5" = mkDarwinSystem {
        username = "shiina";
      };

      "mbp-m1" = mkDarwinSystem {
        username = "shina";
      };
    };

    # For nix-darwin commands
    darwinPackages = self.darwinConfigurations."mbp-m1".pkgs;
  };
}
