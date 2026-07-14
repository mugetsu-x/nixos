{ pkgs, ... }:

let
  # Shared with Neovim — add a language server there, not here.
  tsPackages = import ../lib/ts-packages.nix pkgs;

  # Zed's default behaviour is to download Node and its language servers itself.
  # Those are dynamically linked against an FHS layout that does not exist on
  # NixOS, so they either fail to start or fail silently, leaving you with an
  # editor that has no types. Every binary below is therefore pinned to the Nix
  # store. This is the same reason Mason is disabled in the Neovim config.
  node = "${pkgs.nodejs_22}/bin/node";
  npm = "${pkgs.nodejs_22}/bin/npm";

  prettierd = {
    external = {
      command = "${pkgs.prettierd}/bin/prettierd";
      arguments = [ "{buffer_path}" ];
    };
  };
in
{
  programs.zed-editor = {
    enable = true;

    # Puts the language servers on Zed's PATH. `vtsls` and the tailwind server
    # are Node scripts, so nodejs_22 (in this list) has to be there too.
    extraPackages = tsPackages;

    # NOTE: deliberately *not* using the `extensions` option. It compiles down to
    # `auto_install_extensions = { <each> = true; }` and clobbers that key in
    # userSettings, which leaves no way to mark an extension as unwanted. We need
    # that for `html` — see below — so the map is written out by hand instead.

    userSettings = {
      auto_install_extensions = {
        nix = true;
        catppuccin = true;
        dockerfile = true;
        toml = true;
        env = true;

        # Zed pulls the *latest* extension from a rolling registry, but our Zed is
        # pinned by nixpkgs (0.189.5). The current html extension (0.2.2) uses a
        # newer manifest syntax and fails to parse:
        #   TOML parse error ... block_comment ... invalid type: map
        # Zed auto-installs it on sight of an HTML file, so it has to be pinned off
        # explicitly. Costs nothing here: TSX/JSX/CSS/Tailwind are built into Zed.
        # Revisit when Zed is next bumped.
        html = false;
      };

      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      theme = {
        mode = "dark";
        dark = "Catppuccin Macchiato";
        light = "Catppuccin Macchiato";
      };

      buffer_font_family = "JetBrainsMono Nerd Font Mono";
      buffer_font_size = 14;
      ui_font_size = 15;

      # Evaluate .envrc directly. Without this Zed's language servers run with
      # the ambient environment and miss the per-project devShell that direnv
      # loads, so a project pinning its own Node would be ignored.
      load_direnv = "direct";

      # Never let Zed fetch its own Node.
      node = {
        path = node;
        npm_path = npm;
      };

      # Overriding `binary.path` also throws away the arguments Zed's built-in
      # adapter would have passed, so every server has to be given its own. Miss
      # this and the server starts, gets no transport, and dies immediately:
      #   Error: Connection input stream is not set ... set '--stdio'
      #   ERROR [lsp] cannot read LSP message headers
      # which surfaces as an editor with no diagnostics and no hover types.
      # Anything built on vscode-languageserver (vtsls, eslint, tailwind) needs
      # --stdio; marksman needs its `server` subcommand; nixd speaks stdio by
      # default.
      lsp = {
        vtsls.binary = {
          path = "${pkgs.vtsls}/bin/vtsls";
          arguments = [ "--stdio" ];
        };
        eslint.binary = {
          path = "${pkgs.vscode-langservers-extracted}/bin/vscode-eslint-language-server";
          arguments = [ "--stdio" ];
        };
        tailwindcss-language-server.binary = {
          path = "${pkgs.tailwindcss-language-server}/bin/tailwindcss-language-server";
          arguments = [ "--stdio" ];
        };
        nixd.binary.path = "${pkgs.nixd}/bin/nixd";
        marksman.binary = {
          path = "${pkgs.marksman}/bin/marksman";
          arguments = [ "server" ];
        };
      };

      format_on_save = "on";

      languages =
        let
          web = {
            format_on_save = "on";
            formatter = prettierd;
          };
        in
        {
          TypeScript = web;
          TSX = web;
          JavaScript = web;
          JSX = web;
          JSON = web;
          JSONC = web;
          CSS = web;
          HTML = web;
          Markdown = web;
          YAML = web;

          Nix = {
            # The nix extension ships nil; we use nixd, and nixfmt to match the
            # repo formatter (see CLAUDE.md).
            language_servers = [
              "nixd"
              "!nil"
            ];
            format_on_save = "on";
            formatter.external = {
              command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
              arguments = [ ];
            };
          };
        };

      terminal = {
        shell.program = "${pkgs.zsh}/bin/zsh";
        font_size = 13;
      };

      # The agent panel. Sign-in is interactive on first launch — pick the
      # provider and model there; nothing here touches credentials.
      agent.enabled = true;
    };
  };
}
