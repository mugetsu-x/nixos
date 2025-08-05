{ config, pkgs, ... }: {
  imports = [
    ../modules/hardware.nix
    ../modules/nvidia.nix
    ../modules/common.nix
  ];

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;
}
