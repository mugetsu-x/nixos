{ config, pkgs, home-manager, ... }: {
  imports = [
    ../modules/hardware.nix
    ../modules/nvidia.nix
    ../modules/common.nix
    ../modules/login.nix
    home-manager.nixosModules.home-manager
  ];
  # Hyprland
  programs.hyprland.enable = true;

  # Plasma 6 setup (kept)
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Home Manager user config
  home-manager.users.rennsemml = import ../home/rennsemml.nix;
}
