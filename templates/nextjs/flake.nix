{
  description = "Next.js + Postgres dev environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Loaded automatically by direnv via .envrc (`use flake`). These versions
      # are pinned per project and shadow whatever is in the user profile, so a
      # project can move to a different Node without touching the system config.
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nodejs_22
          pnpm
          typescript
          postgresql_16 # psql client; the server runs in Docker (compose.yaml)
        ];

        shellHook = ''
          echo "node $(node --version)  pnpm $(pnpm --version)"
          echo "db: docker compose up -d   →   $(grep -m1 DATABASE_URL .env.example 2>/dev/null | cut -d= -f2-)"
        '';
      };
    };
}
