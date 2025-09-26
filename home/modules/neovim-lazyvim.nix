{ config, lib, pkgs, ... }:

let
  lazyvimStarter = pkgs.fetchFromGitHub {
    owner = "LazyVim";
    repo  = "starter";
    rev   = "HEAD";  # replace with a commit later for long-term pinning
    sha256 = "sha256-QrpnlDD4r1X4C8PqBhQ+S3ar5C+qDrU1Jm/lPqyMIFM=";
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraPackages = with pkgs; [
      # essentials
      ripgrep
      fd

      # TS / web stack
      nodejs_22
      typescript
      typescript-language-server
      vtsls
      vscode-langservers-extracted   # html, cssls, jsonls, eslint
      prettierd

      # Nix formatting (attr renamed in 25.05)
      nixfmt-classic                 # provides the "nixfmt" binary
    ];
  };

  # Put the LazyVim starter in ~/.config/nvim
  xdg.configFile."nvim".source = lazyvimStarter;

  # Use Nix-installed LSPs (no Mason)
  xdg.configFile."nvim/lua/plugins/lsp-nix.lua".text = ''
    return {
      {
        "neovim/nvim-lspconfig",
        opts = {
          servers = {
            vtsls = { mason = false },
            html  = { mason = false },
            cssls = { mason = false },
            jsonls = { mason = false },
            eslint = { mason = false },
          },
        },
      },
    }
  '';

  # Formatting via conform.nvim: TS/JS + Nix
  xdg.configFile."nvim/lua/plugins/formatters.lua".text = ''
    return {
      {
        "stevearc/conform.nvim",
        opts = function(_, opts)
          opts.formatters_by_ft = vim.tbl_extend("force", opts.formatters_by_ft or {}, {
            -- Web/TS
            javascript        = { "prettierd", "prettier" },
            typescript        = { "prettierd", "prettier" },
            javascriptreact   = { "prettierd", "prettier" },
            typescriptreact   = { "prettierd", "prettier" },
            json              = { "prettierd", "prettier" },
            yaml              = { "prettierd", "prettier" },
            markdown          = { "prettierd", "prettier" },
            -- Nix (nixfmt-classic package supplies the "nixfmt" binary)
            nix               = { "nixfmt" },
          })
        end,
      },
    }
  '';
}
