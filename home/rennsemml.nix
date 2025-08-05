{ config, pkgs, ... }: {
  home.username = "rennsemml";
  home.homeDirectory = "/home/rennsemml";
  home.stateVersion = "25.05";

  # Enable Home Manager itself
  programs.home-manager.enable = true;

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
    };

    initContent = ''
      export EDITOR=nvim
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
    font.size = 13;

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
