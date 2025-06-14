{ config, pkgs, ... }:

{
  home.username = "honswurst";
  home.homeDirectory = "/home/honswurst";

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "mugestu";
    userEmail = "walters@pariggers.com";
  };

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
    shellAliases = {
      flc = "nano ~/nixos-config/flake.nix";
      homec = "nano ~/nixos-config/home/honswurst.nix";
      hostsc = "nano ~/nixos-config/hosts/nixos.nix";
      nixre = "sudo nixos-rebuild switch --flake ~/nixos-config#nixos";
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      bind = [
        "$mod, R, exec, kitty"
        "$mod, SPACE, exec, wofi --show drun"
        "$mod, Q, killactive"
        "CTRL, bracketleft, exec, clipman pick -t wofi"
        "$mod, P, exec, grimblast save area ~/Pictures/screenshot_$(date +%s).png"
        "$mod, E, exec, dolphin"
        "$mod, L, exec, swaylock -f -c 000000"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, Q, exit"
      ];
      exec-once = [
        "waybar &"
        "wl-paste --watch clipman store &"
        "mako &"
      ];
      env = [ "MOZ_ENABLE_WAYLAND,1" ];
    };
  };

  programs.kitty.enable = true;
  programs.wofi.enable = true;
  programs.firefox.enable = true;
  programs.waybar.enable = true;

  services.mako = {
    enable = true;
    settings = {
      background-color = "#1e1e2e";
      text-color       = "#ffffff";
      width            = 300;
      height           = 100;
      margin           = "10";
      padding          = "10";
      border-size      = 2;
      border-color     = "#89b4fa";
      default-timeout  = 5000;
      font             = "Sans 12";
      anchor           = "top-right";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/bmp" = "swayimg.desktop";
      "image/gif" = "swayimg.desktop";
      "image/jpeg" = "swayimg.desktop";
      "image/jpg" = "swayimg.desktop";
      "image/png" = "swayimg.desktop";
      "image/webp" = "swayimg.desktop";
    };
  };

  home.packages = with pkgs; [
    kitty
    wofi
    waybar
    firefox
    clipman
    wl-clipboard
    grim
    slurp
    grimblast
    swayimg
    swaylock
    vlc
    pamixer
    kdePackages.dolphin
    kdePackages.kio
    kdePackages.kio-extras
  ];

  fonts.fontconfig.enable = true;
}
