{ config, pkgs, ... }:

{
  # Hyprland session handling
  programs.uwsm.enable = true;

  # Lightweight login manager
  services.greetd.enable = true;
  programs.regreet.enable = true;

  services.greetd.settings = {
    default_session = {
      command = "regreet";
      user = "greeter";
    };
  };
}
