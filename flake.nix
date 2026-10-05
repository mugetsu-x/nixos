{
  description = "NixOS config for rennsemml’s PC with flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # Zed only. nixos-25.05 froze it at 0.189.5 and stable never bumps it, so a
    # current Zed needs a second nixpkgs. Deliberately *not* `follows`-ed onto
    # nixpkgs — that would pin it back to 25.05 and defeat the whole point.
    # Nothing else may pull from here; see home/modules/zed.nix.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    # Encrypted secrets, decrypted at activation. See modules/secrets.nix.
    # Pinned: sops-nix dropped 25.05 on 2026-02-04 (its Go helper needs Go >= 1.25,
    # 25.05 ships 1.24). This is the last commit before that. Unpin — back to plain
    # "github:Mic92/sops-nix" — when nixpkgs moves to 25.11.
    sops-nix = {
      url = "github:Mic92/sops-nix/17eea6f3816ba6568b8c81db8a4e6ca438b30b7c";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nix-claude-code,
      nix-index-database,
      sops-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      # allowUnfree has to be set here too: `useGlobalPkgs` only inherits the
      # config of the *stable* nixpkgs (modules/common.nix), not this one.
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      # Project scaffolding: `nix flake init -t ~/nixos-config#nextjs` in an empty
      # directory, then `direnv allow`.
      templates.nextjs = {
        path = ./templates/nextjs;
        description = "Next.js + Postgres dev environment (flake devShell, direnv, docker compose)";
      };
      templates.default = self.templates.nextjs;

      nixosConfigurations.main-pc = nixpkgs.lib.nixosSystem {
        inherit system;
        # Add this line to pass the input to your modules
        specialArgs = { inherit nix-claude-code pkgs-unstable; };
        modules = [
          ./hosts/main-pc.nix
          home-manager.nixosModules.home-manager
          nix-index-database.nixosModules.nix-index
          sops-nix.nixosModules.sops
        ];
      };
    };
}
