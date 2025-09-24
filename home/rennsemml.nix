{ config, pkgs, ... }:

let
  # script for auto-connecting trusted BT devices
  btAutoconnect = pkgs.writeShellScript "bt-autoconnect.sh" ''
    set -euo pipefail
    sleep 5
    for mac in $(${pkgs.bluez}/bin/bluetoothctl devices Paired | awk '{print $2}'); do
      if ${pkgs.bluez}/bin/bluetoothctl info "$mac" | grep -q "Trusted: yes"; then
        if ! ${pkgs.bluez}/bin/bluetoothctl info "$mac" | grep -q "Connected: yes"; then
          echo "Connecting $mac"
          ${pkgs.bluez}/bin/bluetoothctl connect "$mac" || true
        fi
      fi
    done
  '';
in {
  home.username = "rennsemml";
  home.homeDirectory = "/home/rennsemml";

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

   # Shell setup
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history.size = 10000;
      shellAliases = {
        nixre = "sudo nixos-rebuild switch --flake ~/nixos-config#main-pc";
        nixhome = "cd ~/nixos-config";
      };
      initContent = ''
        export EDITOR=nvim
      '';
    };

  programs.starship = {
    enable = true;
    settings = {
      scan_timeout = 10;            # default ok
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
        format = "[$path]($style)" ; # tweak as you like
      };

      # Git status with “branch” symbol etc.
      git_branch = { symbol = " "; style = "blue"; };
      git_status = { format = "([$all_status$ahead_behind]($style)) "; style = "yellow"; };

      # Prompt symbol
      character = {
        success_symbol = "[❯](green)";
        error_symbol   = "[❯](red)";
        vicmd_symbol   = "[❮](blue)";
      };
    };
  };



  # Applications
  home.packages = with pkgs; [
    kitty
    libnotify
    wl-clipboard
    cliphist
    wofi
    mako
    pamixer
    pavucontrol
    waybar
    hyprpaper
    firefox
    blueman
    networkmanagerapplet
    speedtest-cli
  ];

  # Kitty
  xdg.configFile."kitty/macchiato.conf".source  = ./kitty/macchiato.conf;

  # Wofi
  xdg.configFile."wofi/style.css".source = ./wofi/style.css;
  xdg.configFile."kitty/kitty.conf".source     = ./kitty/kitty.conf;  

  # Waybar
  xdg.configFile."waybar/config.jsonc".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source   = ./waybar/style.css;

  # Hyprland and paper
  xdg.configFile."hypr/hyprland.conf".source = ./hypr/hyprland.conf;
  xdg.configFile."hypr/hyprpaper.conf".source = ./hypr/hyprpaper.conf;

  # Mako
  xdg.configFile."mako/config".source = ./mako/config;

  home.file.".config/waybar/scripts/net-upload.sh" = {
    source = ./waybar/scripts/net-upload.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/speedtest-download.sh" = {
    source = ./waybar/scripts/speedtest-download.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/ws.sh" = {
    source = ./waybar/scripts/ws.sh;
    executable = true;
  };


  # Systemd user service: clipboard history
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


  # Systemd user service: auto-connect Bluetooth trusted devices
  systemd.user.services.bt-autoconnect = {
    Unit = {
      Description = "Auto-connect trusted Bluetooth devices";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = btAutoconnect;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
