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
      overlays = [ (import "${nixpkgs-wayland}/overlay.nix") ];
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/nixos.nix

          # Home Manager integrated into system
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
        modules = [ ./home.nix ];
        username = "honswurst";
        homeDirectory = "/home/honswurst";
      };
    };
}
