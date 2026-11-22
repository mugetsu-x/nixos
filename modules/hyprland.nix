{ config, pkgs, ... }:
{
  # The Hyprland session itself, shared by every desktop host. Greeter and
  # autologin are in login.nix. main-pc overrides the package with its tablet
  # patches (hosts/main-pc.nix).
  programs.hyprland.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      # Not pkgs.xdg-desktop-portal-hyprland: programs.hyprland builds its portal
      # against the (patched) Hyprland package, and a second, stock copy collides
      # with it over xdg-desktop-portal-hyprland.service.
      config.programs.hyprland.portalPackage
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "hyprland"
      "gtk"
    ];
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
