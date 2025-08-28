{ config, pkgs, ... }: {
  home.username = "rennsemml";
  home.homeDirectory = "/home/rennsemml";
  home.stateVersion = "25.05";
  home.packages = with pkgs; [
    wofi
    mako
    wl-clipboard
    cliphist
    pamixer
    pavucontrol
    waybar
    hyprpaper
    hyprland
    libnotify
    wev
  ];

  systemd.user.services.cliphist-store = {
    Unit = {
      Description = "Wayland clipboard history daemon";
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };


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
        cd ~/nixos-config || return
        git add .
        git commit -m "$*"
	git push
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
  
  # Hyprland
  xdg.configFile."hypr/hyprland.conf".source = ./hypr/hyprland.conf;

  # Hyprpapr
  xdg.configFile."hypr/hyprpaper.conf".source = ./hypr/hyprpaper.conf;

  # Waybar
  xdg.configFile."waybar/config.jsonc".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source   = ./waybar/style.css;
  
  # Wofi
  xdg.configFile."wofi/style.css".source = ./wofi/style.css;

  # Mako
  xdg.configFile."mako/config".source = ./mako/config;

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
