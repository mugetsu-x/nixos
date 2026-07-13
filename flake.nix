{
  description = "NixOS config for rennsemml’s PC with flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-claude-code = {
      url = "github:ryoppippi/nix-claude-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Ships a prebuilt nix-index database, so `comma` and `nix-locate` work
    # without spending half an hour indexing nixpkgs locally.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, home-manager, nix-claude-code, nix-index-database, ... }: {
      nixosConfigurations.main-pc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # Add this line to pass the input to your modules
        specialArgs = { inherit nix-claude-code; };
        modules = [
          ./hosts/main-pc.nix
          home-manager.nixosModules.home-manager
          nix-index-database.nixosModules.nix-index
        ];
      };
    };
}
