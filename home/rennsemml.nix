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
      nixpush = "cd ~/nixos-config && git add . && git commit -m \"$1\" && git push";
    };
    initContent = ''
      export EDITOR=nvim
    '';
  };

  programs.starship.enable = true;

  # Applications
  home.packages = with pkgs; [
    # terminal
    kitty

    # notifications + clipboard
    libnotify
    wl-clipboard
    cliphist
    wofi
    mako

    # volume + audio
    pamixer
    pavucontrol

    # bar + wallpaper
    waybar
    hyprpaper

    # browser
    firefox

    # utils
    blueman
  ];

  # Kitty config
  xdg.configFile."kitty/kitty.conf".source = ./macchiato.conf;

  # Waybar config
  xdg.configFile."waybar/config.jsonc".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source   = ./waybar/style.css;

  # Hyprpaper config
  xdg.configFile."hypr/hyprpaper.conf".source = ./hypr/hyprpaper.conf;

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
