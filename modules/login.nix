{ config, pkgs, lib, ... }:

{
  #### UWSM + Hyprland session ####
  programs.uwsm.enable = true;
  programs.uwsm.waylandCompositors.hyprland = {
    prettyName = "Hyprland";
    comment   = "Hyprland compositor managed by UWSM";
    binPath   = "/run/current-system/sw/bin/Hyprland";
  };

  #### Greeter (greetd + regreet) ####
  services.greetd.enable = true;

  programs.regreet = {
    enable = true;

    # Minimal config: just wallpaper + clock (+ a few env niceties)
    settings = {
      prefer_dark = true;

      clock = {
        enabled = true;
        format = "%A, %d %B %Y  %H:%M";
      };

      env = {
        NIXOS_OZONE_WL      = "1";
        QT_QPA_PLATFORM     = "wayland";
        XDG_CURRENT_DESKTOP = "Hyprland";
      };
    };
  };

  # Run ReGreet inside cage so GTK has a Wayland compositor
  services.greetd.settings.default_session = {
    user = "greeter";
    command = "${pkgs.cage}/bin/cage -s -- ${config.programs.regreet.package}/bin/regreet";
  };
}
