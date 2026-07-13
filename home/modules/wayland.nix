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

  # These modules only generate a config file when their `settings` option is
  # set. We leave `settings` empty on purpose, so the raw dotfiles linked above
  # stay the source of truth and we get the systemd units for free.
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };
  services.hyprpaper.enable = true;

  # No systemd unit: home-manager wires mako up for D-Bus activation, so it
  # starts on the first notification.
  services.mako.enable = true;

  programs.hyprlock.enable = true;
  programs.hyprlock.settings = { };
  services.hypridle.enable = true;

}
