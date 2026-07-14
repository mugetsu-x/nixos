# The TypeScript/web language servers and formatters, in one place.
#
# Both the Neovim module and the Zed module consume this list, so a new language
# server is added once here instead of drifting between two lists. Neither editor
# is allowed to download its own servers: Mason is disabled in Neovim, and Zed's
# settings point at these binaries explicitly (see home/modules/zed.nix). Servers
# fetched at runtime are dynamically linked against an FHS layout that does not
# exist on NixOS, so they would fail to start.
#
# Usage: `tsPackages = import ../lib/ts-packages.nix pkgs;`
pkgs: with pkgs; [
  # Runtime. Editors shell out to this for the TS server and for prettier.
  nodejs_22
  typescript

  # TypeScript / web
  vtsls
  vscode-langservers-extracted # html, cssls, jsonls, eslint
  tailwindcss-language-server
  prettierd

  # Nix
  nixd # language server
  nixfmt-rfc-style # the "nixfmt" binary — repo formatter, see CLAUDE.md

  # Markdown
  marksman
]
