{
  description = "NixOS config for rennsemml’s PC with flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.main-pc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/main-pc.nix home-manager.nixosModules.home-manager ];
    };
  };
}
