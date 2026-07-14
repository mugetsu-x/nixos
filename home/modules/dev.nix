{ pkgs, ... }:
{
  # The baseline development toolchain, available in every shell.
  #
  # Per-project toolchains still come from a flake devShell loaded by direnv (see
  # templates/nextjs), and those take precedence — this is the fallback so that a
  # bare terminal, and any AI agent spawned into one, always has a working `node`,
  # `pnpm` and `tsc` rather than nothing at all.
  home.packages = with pkgs; [
    nodejs_22 # also provides npm
    pnpm # default package manager for new projects
    typescript # tsc

    postgresql_16 # for the psql client; the server runs in Docker per project
    httpie # `http GET localhost:3000/api/...`
  ];
}
