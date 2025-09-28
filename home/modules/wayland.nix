{ config, pkgs, ... }: {
  # Kitty
  xdg.configFile."kitty/macchiato.conf".source =
    ../dotfiles/kitty/macchiato.conf;
  xdg.configFile."kitty/kitty.conf".source = ../dotfiles/kitty/kitty.conf;

  # Wofi
  xdg.configFile."wofi/style.css".source = ../dotfiles/wofi/style.css;

  # Waybar
  xdg.configFile."waybar/config.jsonc".source = ../dotfiles/waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ../dotfiles/waybar/style.css;

  # Hyprland & Hyprpaper
  xdg.configFile."hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
  xdg.configFile."hypr/hyprpaper.conf".source = ../dotfiles/hypr/hyprpaper.conf;

  # Mako
  xdg.configFile."mako/config".source = ../dotfiles/mako/config;

  programs.hyprlock.enable = true;
  programs.hyprlock.settings = { };
  services.hypridle.enable = true;

}
