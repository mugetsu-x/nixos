{ config, pkgs, home-manager, ... }: {
  imports = [
    ../modules/hardware.nix
    ../modules/nvidia.nix
    ../modules/common.nix
    home-manager.nixosModules.home-manager
  ];

  # Plasma 6 setup
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Home Manager user config
  home-manager.users.rennsemml = import ../home/rennsemml.nix;

  nixpkgs.config.allowUnfree = true;
}
