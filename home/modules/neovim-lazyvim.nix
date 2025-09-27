{ config, lib, pkgs, ... }:

let
  lazyvimStarter = pkgs.fetchFromGitHub {
    owner = "LazyVim";
    repo = "starter";
    rev = "HEAD"; # pin to a commit later for long-term reproducibility
    sha256 = "sha256-QrpnlDD4r1X4C8PqBhQ+S3ar5C+qDrU1Jm/lPqyMIFM=";
  };
in {
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
      vscode-langservers-extracted # html, cssls, jsonls, eslint
      prettierd

      # Nix formatting
      nixfmt-classic # provides the "nixfmt" binary

      # Markdown
      marksman # Markdown LSP
      glow # optional: terminal preview
    ];
  };

  # Put LazyVim starter into ~/.config/nvim (and merge our tweaks)
  home.file.".config/nvim" = {
    source = lazyvimStarter;
    recursive = true;
    force = true;
  };

  # --- Plugin customizations (explicitly under $HOME using home.file) ---

  # 1) Enable Markdown extras (Treesitter, sensible defaults)
  home.file.".config/nvim/lua/plugins/extras.lua".text = ''
    return {
      { import = "lazyvim.plugins.extras.lang.markdown" },
    }
  '';

  # 2) LSP: use Nix-installed binaries (no Mason)
  home.file.".config/nvim/lua/plugins/lsp-nix.lua".text = ''
    return {
      {
        "neovim/nvim-lspconfig",
        opts = {
          servers = {
            -- TypeScript / Web
            vtsls = { mason = false },
            html  = { mason = false },
            cssls = { mason = false },
            jsonls = { mason = false },
            eslint = { mason = false },
            -- Markdown
            marksman = { mason = false },
          },
        },
      },
    }
  '';

  # 3) Formatting via conform.nvim: TS/JS + Markdown + Nix
  home.file.".config/nvim/lua/plugins/formatters.lua".text = ''
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
            -- Nix (nixfmt-classic provides "nixfmt")
            nix               = { "nixfmt" },
          })
        end,
      },
    }
  '';
}

