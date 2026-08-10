{
  config,
  pkgs,
  lib,
  ...
}:

{
  #### UWSM + Hyprland session ####
  programs.uwsm.enable = true;
  programs.uwsm.waylandCompositors.hyprland = {
    prettyName = "Hyprland";
    comment = "Hyprland compositor managed by UWSM";
    binPath = "/run/current-system/sw/bin/Hyprland";
  };

  #### Greeter (greetd + regreet) ####
  services.greetd.enable = true;

  programs.regreet = {
    enable = true;
    settings = {
      prefer_dark = true;
      clock = {
        enabled = true;
        format = "%A, %d %B %Y  %H:%M";
      };
      env = {
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
        XDG_CURRENT_DESKTOP = "Hyprland";
      };
    };
  };

  # Run ReGreet inside cage so GTK has a Wayland compositor
  services.greetd.settings.default_session = {
    user = "greeter";
    command = "${pkgs.cage}/bin/cage -s -- ${config.programs.regreet.package}/bin/regreet";
  };

  # Autologin: skip the greeter entirely on boot and go straight to Hyprland.
  # `initial_session` fires *once*, at boot; log out and you land back on
  # `default_session` (ReGreet) above, which is the intended escape hatch.
  #
  # Start Hyprland through uwsm, not directly: uwsm is what binds the session
  # into graphical-session.target, and without it every systemd user unit
  # (waybar, hyprpaper, cliphist, udiskie, ...) has nothing to key off and
  # never starts. This is the same command the generated
  # hyprland-uwsm.desktop entry runs, spelled out — the entry itself only
  # exists inside displayManager.sessionData, not on a stable system path.
  services.greetd.settings.initial_session = {
    user = "rennsemml";
    command = "${lib.getExe config.programs.uwsm.package} start -S -F ${config.programs.uwsm.waylandCompositors.hyprland.binPath}";
  };
}
