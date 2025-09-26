{ config, lib, pkgs, ... }:

let
  # Pin the official LazyVim starter (fetch once, reproducible)
  lazyvimStarter = pkgs.fetchFromGitHub {
    owner = "LazyVim";
    repo  = "starter";
    # Pick a recent commit from https://github.com/LazyVim/starter
    # First build will suggest the correct sha256; replace lib.fakeSha256 then.
    rev = "HEAD";
    sha256 = lib.fakeSha256;
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Put dev tools / LSPs on $PATH inside nvim (and for :!cmd)
    extraPackages = with pkgs; [
      # general cli helpers used by plugins
      ripgrep fd jq git
      # JS/TS toolchain
      nodejs_22 typescript typescript-language-server vtsls
      vscode-langservers-extracted  # html/css/json/eslint LSPs
      prettierd                      # faster Prettier daemon
      # Lua
      lua-language-server stylua
      # Python
      python312         # interpreter for lint/format if needed
      basedpyright      # or pkgs.pyright if you prefer
      ruff ruff-lsp     # linter / LSP
      black             # formatter (optional)
      # Nix
      nixd              # or nil, pick one
      # Shell / YAML / Markdown
      bash-language-server yaml-language-server marksman
      # C#
      omnisharp-roslyn netcoredbg
    ];

    # You can also pin some plugins from nixpkgs if you want to avoid network,
    # but LazyVim starter will let lazy.nvim resolve plugin pins itself.
    # Example to add a plugin from nixpkgs:
    # plugins = with pkgs.vimPlugins; [ nvim-web-devicons ];
  };

  # Provide LazyVim starter as your ~/.config/nvim (managed by HM)
  xdg.configFile."nvim".source = lazyvimStarter;

  # ---- LazyVim customization: prefer Nix-installed tools over Mason ----
  # 1) LSP: tell LazyVim that servers are provided by the system (mason=false)
  xdg.configFile."nvim/lua/plugins/lsp-nix.lua".text = ''
    return {
      -- Adjust default LSPs to use system binaries (nix) instead of Mason
      {
        "neovim/nvim-lspconfig",
        opts = {
          servers = {
            lua_ls = { mason = false },
            -- LazyVim’s TS extra uses vtsls by default (since v11+).
            -- Ensure we don’t try to install via Mason:
            vtsls = { mason = false },
            html  = { mason = false },
            cssls = { mason = false },
            jsonls = { mason = false },
            eslint = { mason = false },
            bashls = { mason = false },
            yamlls = { mason = false },
            marksman = { mason = false },
            nixd = { mason = false }, -- or nil = { mason = false }
            omnisharp = { mason = false },
            basedpyright = { mason = false }, -- or pyright = { mason = false }
          },
        },
      },
    }
  '';

  # 2) Formatting: map formatters to the binaries we installed with nix
  #    LazyVim uses conform.nvim by default; we only tweak which executables to prefer.
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
            nix = { "nixfmt" }, -- or "alejandra"
            python = { "ruff_format", "black" }, -- choose your fav
            sh = { "shfmt" },
          })
        end,
      },
    }
  '';

  # 3) Optional: enable some curated LazyVim extras declaratively.
  #    (You can also toggle at runtime with :LazyExtras)
  #    See https://lazyvim.github.io/news (vtsls switch) and docs
  xdg.configFile."nvim/lua/plugins/extras.lua".text = ''
    return {
      -- Examples:
      -- { import = "lazyvim.plugins.extras.lang.typescript" },
      -- { import = "lazyvim.plugins.extras.lang.python" },
      -- { import = "lazyvim.plugins.extras.lang.json" },
      -- { import = "lazyvim.plugins.extras.ui.mini-animate" },
      -- Add/remove as you like; leaving empty is fine.
    }
  '';
}
