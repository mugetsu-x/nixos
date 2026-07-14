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

  # Hyprland, Hyprpaper & Hyprlock
  xdg.configFile."hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
  xdg.configFile."hypr/hyprpaper.conf".source = ../dotfiles/hypr/hyprpaper.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ../dotfiles/hypr/hyprlock.conf;

  # Mako
  xdg.configFile."mako/config".source = ../dotfiles/mako/config;

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
    "${../dotfiles/waybar/config.jsonc}"
    "${../dotfiles/waybar/style.css}"
  ];
  # Static wallpaper. hyprpaper.conf names DP-2 explicitly; DP-4's background
  # layer belongs to mpvpaper below.
  services.hyprpaper.enable = true;

  # Video wallpaper on DP-4 only. No home-manager module exists for mpvpaper, so
  # this is hand-written — but it is still a systemd user unit, not an
  # `exec-once`. mpvpaper is referenced by store path rather than added to
  # home.packages: nothing else needs it on PATH.
  #
  # ConditionPathExists keeps the unit inert (not failed, not looping) until a
  # video is actually in place, so a fresh checkout switches cleanly.
  systemd.user.services.mpvpaper = {
    Unit = {
      Description = "Video wallpaper on DP-4";
      ConditionPathExists = "%h/Videos/wallpapers/live.mp4";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      # --auto-pause stops decoding whenever the wallpaper is covered, which on
      # this machine is most of the time. hwdec=auto picks nvdec on the NVIDIA
      # open driver.
      ExecStart = ''
        ${pkgs.mpvpaper}/bin/mpvpaper --auto-pause -o "no-audio loop-file=inf hwdec=auto panscan=1.0" DP-4 %h/Videos/wallpapers/live.mp4
      '';
      # mpvpaper is prone to dying on DPMS/mode changes; heal instead of going
      # black until it is noticed.
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # No systemd unit: home-manager wires mako up for D-Bus activation, so it
  # starts on the first notification.
  services.mako.enable = true;

  programs.hyprlock.enable = true;
  programs.hyprlock.settings = { };
  services.hypridle.enable = true;

}
