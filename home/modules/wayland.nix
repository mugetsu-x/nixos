{ config, pkgs, ... }:
{
  # Kitty
  xdg.configFile."kitty/macchiato.conf".source = ../dotfiles/kitty/macchiato.conf;
  xdg.configFile."kitty/kitty.conf".source = ../dotfiles/kitty/kitty.conf;

  # Wofi
  xdg.configFile."wofi/style.css".source = ../dotfiles/wofi/style.css;

  # Everything in this file is shared by the desktop hosts. What depends on the
  # machine — hypr/host.conf, hypr/hyprpaper.conf and waybar/config.jsonc — is
  # linked by desktop-main-pc.nix / desktop-xps13.nix instead.

  # Waybar: the shared module definitions, included by the host's config.jsonc.
  xdg.configFile."waybar/common.jsonc".source = ../dotfiles/waybar/common.jsonc;
  xdg.configFile."waybar/style.css".source = ../dotfiles/waybar/style.css;

  # Hyprland, Hyprlock & Hypridle
  xdg.configFile."hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ../dotfiles/hypr/hyprlock.conf;
  xdg.configFile."hypr/hypridle.conf".source = ../dotfiles/hypr/hypridle.conf;

  # Mako
  xdg.configFile."mako/config".source = ../dotfiles/mako/config;

  # Swappy (screenshot editor behind SUPER+P). It does not create save_dir
  # itself, so a tmpfiles rule makes sure the folder exists.
  xdg.configFile."swappy/config".source = ../dotfiles/swappy/config;
  systemd.user.tmpfiles.rules = [ "d %h/Pictures/Screenshots - - - -" ];

  # These modules only generate a config file when their `settings` option is
  # set. We leave `settings` empty on purpose, so the raw dotfiles linked above
  # stay the source of truth and we get the systemd units for free.
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  # Waybar's clock calendar does not survive a reload: the widget is not
  # re-initialised and the tooltip is dead until the process actually restarts
  # (Alexays/Waybar#3383). The unit's ExecReload is `kill -SIGUSR2`, so a switch
  # that swaps the config/style symlinks silently breaks the calendar. Listing
  # the dotfiles here makes the unit file itself change whenever they do, which
  # gets us a real restart instead of a reload.
  systemd.user.services.waybar.Unit.X-Restart-Triggers = [
    "${../dotfiles/waybar/common.jsonc}"
    "${../dotfiles/waybar/style.css}"
  ];
  # Static wallpaper. hyprpaper reads its config once at startup, so the host
  # module that links hyprpaper.conf also lists it as a restart trigger.
  services.hyprpaper.enable = true;

  # No systemd unit: home-manager wires mako up for D-Bus activation, so it
  # starts on the first notification.
  services.mako.enable = true;

  programs.hyprlock.enable = true;
  programs.hyprlock.settings = { };

  # Like the others, `settings` stays empty and hypridle.conf above is the
  # source of truth. That file is not optional: with no config at all hypridle
  # aborts on start ("Could not find config") and Restart=always turns that
  # into a core dump every 10s.
  services.hypridle.enable = true;
  # hypridle reads its config once at startup; restart it when the file changes
  # so a switch actually applies new timeouts.
  systemd.user.services.hypridle.Unit.X-Restart-Triggers = [
    "${../dotfiles/hypr/hypridle.conf}"
  ];

}
