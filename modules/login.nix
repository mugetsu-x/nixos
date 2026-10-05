{
  config,
  pkgs,
  lib,
  ...
}:

{
  #### UWSM + Hyprland session ####
  # Use the session entry Hyprland itself ships (hyprland-uwsm.desktop, shown
  # in ReGreet as "Hyprland (uwsm-managed)"): `uwsm start -e -D Hyprland
  # hyprland.desktop`, which runs `start-hyprland`. Since 0.53 Hyprland
  # expects to be launched through that watchdog wrapper and complains on
  # every login otherwise. Do not go back to a hand-written
  # `programs.uwsm.waylandCompositors.hyprland` entry: it points uwsm at the
  # bare `Hyprland` binary, and because it is also named hyprland-uwsm.desktop
  # it shadows the upstream one.
  programs.hyprland.withUWSM = true;

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
  # never starts. This is the same command the upstream hyprland-uwsm.desktop
  # entry runs (see above), spelled out: uwsm resolves `hyprland.desktop` from
  # the wayland-sessions dirs, and its Exec is `start-hyprland`.
  #
  # Use only flags uwsm still has. An unknown one (0.26 dropped `-S`) makes it
  # exit on argparse before Hyprland starts, and autologin silently falls
  # through to ReGreet.
  services.greetd.settings.initial_session = {
    user = "rennsemml";
    command = "${lib.getExe config.programs.uwsm.package} start -e -D Hyprland hyprland.desktop";
  };
}
