{ config, lib, pkgs, ... }:

let
  # Pin the official LazyVim starter (reproducible)
  lazyvimStarter = pkgs.fetchFromGitHub {
    owner = "LazyVim";
    repo  = "starter";
    # For long-term reproducibility, replace HEAD with a commit hash when you want.
    rev = "HEAD";
    # Use the hash your build printed ("got: ..."):
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

    # Make dev tools/LSPs available inside nvim
    extraPackages = with pkgs; [
      # handy CLIs
      ripgrep fd jq

      # Nix formatting (attr renamed in 25.05)
      nixfmt-classic
      shfmt

      # TS/JS
      nodejs_22 typescript typescript-language-server vtsls
      vscode-langservers-extracted   # html, css, json, eslint LSPs
      prettierd                       # fast prettier daemon

      # Lua
      lua-language-server stylua

      # Python
      python312
      basedpyright  # or pyright
      ruff          # linter (diagnostics via nvim-lint)
      black         # optional formatter

      # Nix LSP
      nixd          # or nil

      # Shell / YAML / Markdown LSPs
      bash-language-server yaml-language-server marksman

      # C#
      omnisharp-roslyn netcoredbg
    ];
  };

  # Provide the LazyVim starter as your ~/.config/nvim/
  xdg.configFile."nvim".source = lazyvimStarter;

  # --- Plugin customizations (all paths are INSIDE $HOME):
  # 1) LSP: tell LazyVim to use system binaries (mason = false)
  xdg.configFile."nvim/lua/plugins/lsp-nix.lua".text = ''
    return {
      {
        "neovim/nvim-lspconfig",
        opts = {
          servers = {
            -- Lua
            lua_ls = { mason = false },
            -- TypeScript / Web
            vtsls = { mason = false },
            html  = { mason = false },
            cssls = { mason = false },
            jsonls = { mason = false },
            eslint = { mason = false },
            -- Python
            basedpyright = { mason = false }, -- or pyright = { mason = false }
            -- Shell / YAML / Markdown
            bashls = { mason = false },
            yamlls = { mason = false },
            marksman = { mason = false },
            -- Nix
            nixd = { mason = false }, -- or nil = { mason = false }
            -- C#
            omnisharp = { mason = false },
          },
        },
      },
    }
  '';

  # 2) Formatting via conform.nvim — map to Nix-installed executables
  xdg.configFile."nvim/lua/plugins/formatters.lua".text = ''
    return {
      {
        "stevearc/conform.nvim",
        opts = function(_, opts)
          opts.formatters_by_ft = vim.tbl_extend("force", opts.formatters_by_ft or {}, {
            lua = { "stylua" },
            javascript = { "prettierd", "prettier" },
            typescript = { "prettierd", "prettier" },
            javascriptreact = { "prettierd", "prettier" },
            typescriptreact = { "prettierd", "prettier" },
            json = { "prettierd", "prettier" },
            yaml = { "prettierd", "prettier" },
            markdown = { "prettierd", "prettier" },
            -- nixfmt-classic provides the "nixfmt" binary on PATH; if your PATH exposes "nixfmt-classic" instead, replace below accordingly.
            nix = { "nixfmt" },
            python = { "ruff_format", "black" }, -- choose your favorite
            sh = { "shfmt" },
          })
        end,
      },
    }
  '';

  # 3) Linting via nvim-lint — run ruff for Python; lint on save
  xdg.configFile."nvim/lua/plugins/linting.lua".text = ''
    return {
      {
        "mfussenegger/nvim-lint",
        optional = true,
        opts = function(_, opts)
          opts.linters_by_ft = vim.tbl_extend("force", opts.linters_by_ft or {}, {
            python = { "ruff" },
          })
          -- Lint on save
          vim.api.nvim_create_autocmd({ "BufWritePost" }, {
            callback = function()
              require("lint").try_lint()
            end,
          })
        end,
      },
    }
  '';

  # 4) Optional: place to declare LazyVim extras declaratively
  #    (You can also toggle at runtime via :LazyExtras)
  xdg.configFile."nvim/lua/plugins/extras.lua".text = ''
    return {
      -- Examples to enable:
      -- { import = "lazyvim.plugins.extras.lang.typescript" },
      -- { import = "lazyvim.plugins.extras.lang.python" },
      -- { import = "lazyvim.plugins.extras.lang.json" },
      -- { import = "lazyvim.plugins.extras.ui.mini-animate" },
    }
  '';
}
