{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.size = 10000;

    shellAliases = {
      # NicOs worflow
      nixre = "sudo nixos-rebuild switch --flake ~/nixos-config#main-pc";
      nixhome = "cd ~/nixos-config";

      # Editors
      svi = "sudo -e"; # sudoedit → uses $EDITOR (nvim)
      nvi = "nvim"; # same behavior as vi

      # Tools
      pdf = "okular";
      lgit = "lazygit";
      ldocker = "lazydocker";
    };

    # initExtra is deprecated → use initContent
    initContent = ''
      export EDITOR=nvim
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      scan_timeout = 10;
      palette = "catppuccin_macchiato";
      palettes.catppuccin_macchiato = {
        text = "#cad3f5";
        green = "#a6da95";
        blue = "#8aadf4";
        red = "#ed8796";
        yellow = "#eed49f";
      };
      directory = {
        style = "bold green";
        read_only = " ";
        format = "[$path]($style)";
      };
      git_branch = {
        symbol = " ";
        style = "blue";
      };
      git_status = {
        format = "([$all_status$ahead_behind]($style)) ";
        style = "yellow";
      };
      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
        vicmd_symbol = "[❮](blue)";
      };
    };
  };
}

