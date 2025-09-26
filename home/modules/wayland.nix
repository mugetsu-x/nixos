{ pkgs, ... }:
{
  # Kitty
  xdg.configFile."kitty/macchiato.conf".source = ../kitty/macchiato.conf;
  xdg.configFile."kitty/kitty.conf".source     = ../kitty/kitty.conf;

  # Wofi
  xdg.configFile."wofi/style.css".source       = ../wofi/style.css;

  # Waybar
  xdg.configFile."waybar/config.jsonc".source  = ../waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source     = ../waybar/style.css;

  # Hyprland & Hyprpaper
  xdg.configFile."hypr/hyprland.conf".source   = ../hypr/hyprland.conf;
  xdg.configFile."hypr/hyprpaper.conf".source  = ../hypr/hyprpaper.conf;

  # Mako
  xdg.configFile."mako/config".source          = ../mako/config;

  # Waybar scripts
  home.file.".config/waybar/scripts/net-upload.sh" = {
    source = ../waybar/scripts/net-upload.sh;
    executable = true;
  };
  home.file.".config/waybar/scripts/speedtest-download.sh" = {
    source = ../waybar/scripts/speedtest-download.sh;
    executable = true;
  };
  home.file.".config/waybar/scripts/ws.sh" = {
    source = ../waybar/scripts/ws.sh;
    executable = true;
  };
}
