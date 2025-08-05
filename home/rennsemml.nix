{ config, pkgs, ... }: {
  home.username = "rennsemml";
  home.homeDirectory = "/home/rennsemml";
  home.stateVersion = "25.05";

  # Enable Home Manager itself
  programs.home-manager.enable = true;

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # Optional: override some modules for cleaner look
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$character";
      directory.truncation_length = 3;
      git_branch.symbol = "🌱 ";
      character.success_symbol = "[➜](bold green)";
      character.error_symbol = "[✗](bold red)";
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
    };

    shellAliases = {
      ll = "ls -l";
      nixhome = "cd ~/nixos-config";
      nixre = "sudo nixos-rebuild switch --flake ~/nixos-config#main-pc";
      nixpush = "cd ~/nixos-config && git add . && git commit -m";
      hm = "home-manager switch --flake ~/nixos-config/rennsemml";
    };

    initContent = ''
      export EDITOR=nvim
    
      nixpush() {
        cd ~/nixos-config || return 1
        git add .
        if git diff --cached --quiet; then
          echo "🟡 Nothing to commit."
          return 0
        fi

        git commit -m "$*" || return 1
        git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1
        if [ $? -ne 0 ]; then
          echo "🔁 No upstream set. Pushing with upstream tracking..."
          git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
        else
          git push
        fi
      }
    '';
  };


  programs.git = {
    enable = true;
    userName = "Zaraki";
    userEmail = "walter@pariggers.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      color.ui = "auto";
    };
  };


  # Kitty terminal config
  programs.kitty = {
    enable = true;

    font.name = "JetBrainsMono Nerd Font";
    font.size = 11;

    settings = {
      background_opacity = "0.8";
      hide_window_decorations = "yes";
      confirm_os_window_close = "0";
      enable_audio_bell = "no";
      cursor_shape = "beam";
      cursor_blink_interval = "0";
    };

    # All advanced keybinds + theme include go here
    extraConfig = ''
      include ${./kitty/macchiato.conf}

      map ctrl+shift+c copy_to_clipboard
      map ctrl+shift+v paste_from_clipboard
    '';
  };
}
