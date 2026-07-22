{ pkgs, ... }:

# A deliberately small Neovim. Not an IDE. It exists for two jobs: a fast
# throwaway editor (git commits, config files, $EDITOR) and a good Markdown
# editor. Zed is the primary editor for real coding — see home/modules/zed.nix.
#
# Design rules (keep it this way):
#   - No completion engine. No auto-pairs. No coding language servers.
#     The only LSP is marksman, for Markdown link navigation + on-demand
#     omni-completion (<C-x><C-o>), never as-you-type popups.
#   - Every plugin comes from nixpkgs. Nothing is fetched at runtime, so there
#     is no lazy.nvim, no Mason, and no lock file to bump.
#   - Treesitter grammars are compiled by Nix (withPlugins), not downloaded.

let
  treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
    # Required by render-markdown.
    p.markdown
    p.markdown_inline
    # Handful of grammars for the "quick editor" role.
    p.lua
    p.nix
    p.bash
    p.json
    p.yaml
    p.toml
    p.vim
    p.vimdoc
  ]);
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # marksman = Markdown LSP; ripgrep/fd for :grep and file jumping.
    extraPackages = with pkgs; [
      marksman
      ripgrep
      fd
    ];

    plugins = with pkgs.vimPlugins; [
      treesitter
      catppuccin-nvim
      mini-icons # icons used by render-markdown (code fences, callouts)
      render-markdown-nvim # in-buffer Markdown rendering
      nvim-lspconfig # wires up marksman
    ];

    extraLuaConfig = ''
      -- ── Options ───────────────────────────────────────────────────────────
      local opt = vim.opt
      opt.number = true
      opt.mouse = "a"
      opt.clipboard = "unnamedplus"   -- share the system clipboard
      opt.ignorecase = true
      opt.smartcase = true
      opt.expandtab = true
      opt.shiftwidth = 2
      opt.tabstop = 2
      opt.termguicolors = true        -- required for the theme
      opt.signcolumn = "yes"
      opt.undofile = true             -- persistent undo
      opt.scrolloff = 4
      opt.splitright = true
      opt.splitbelow = true
      opt.completeopt = "menuone,noselect"  -- tidy omni-complete menu

      vim.g.mapleader = " "

      -- ── Theme ─────────────────────────────────────────────────────────────
      require("catppuccin").setup({ flavour = "macchiato", background = { dark = "macchiato" } })
      vim.cmd.colorscheme("catppuccin-macchiato")

      -- ── Treesitter (grammars provided by Nix) ─────────────────────────────
      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        indent = { enable = true },
      })

      -- ── Markdown rendering ────────────────────────────────────────────────
      require("mini.icons").setup()
      require("render-markdown").setup({})

      -- ── Markdown LSP: marksman ────────────────────────────────────────────
      -- Link completion is on demand (<C-x><C-o>), not automatic.
      require("lspconfig").marksman.setup({})

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local map = function(keys, fn) vim.keymap.set("n", keys, fn, { buffer = ev.buf }) end
          map("gd", vim.lsp.buf.definition)
          map("gr", vim.lsp.buf.references)
          map("K", vim.lsp.buf.hover)
          map("<leader>rn", vim.lsp.buf.rename)
        end,
      })

      -- ── A couple of quick-editor conveniences ─────────────────────────────
      vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")  -- clear search highlight
      vim.keymap.set("n", "<leader>w", "<cmd>write<CR>")
    '';
  };
}
