{
  description = "Walter's NixOS + Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-wayland, home-manager, flake-utils, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            gtkgreet = prev.callPackage (
              final.fetchFromGitHub {
                owner = "dragonbuild";
                repo = "gtkgreet";
                rev = "b24d0c7f2c44b0cd70ea0d9a5e4cc789edab242f";
                sha256 = "sha256-XyF4PdB8c+6XGEW6hHfqEbfAVXpKsqfAHIQ8odA6xdM=";
              }
            ) {};
          })
        ];
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/nixos.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.honswurst = import ./home/honswurst.nix;
          }
        ];
      };

      homeConfigurations.honswurst = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit system; };
        modules = [ ./home/honswurst.nix ];
      };
    };
}
