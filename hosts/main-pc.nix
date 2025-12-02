{ config, pkgs, home-manager, ... }: {
  imports = [
    ../modules/hardware.nix
    ../modules/nvidia.nix
    ../modules/common.nix
    ../modules/login.nix
  ];
  services.printing.enable = true;

  home-manager.backupFileExtension = "hm-bak";
  hardware.printers = {
    ensurePrinters = [{
      name = "brother-hl-l8260cdw";
      description = "Brother HL-L8260CDW (Wi-Fi)";
      deviceUri = "ipp://192.168.0.9:631/ipp/print";
      model = "everywhere"; # IPP Everywhere (driverless)
      # ppdOptions = { Duplex = "DuplexNoTumble"; };  # optional tweaks
    }];

    ensureDefaultPrinter = "brother-hl-l8260cdw";
  };

  # Hyprland
  programs.hyprland.enable = true;

  # Plasma 6 setup (kept)
  services.xserver.enable = false;
  services.displayManager.sddm.enable = false;
  services.desktopManager.plasma6.enable = false;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals =
      [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [ "hyprland" "gtk" ];
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  users.users.rennsemml.extraGroups = [ "docker" ];

  # Home Manager user config
  home-manager.users.rennsemml = import ../home/rennsemml.nix;
}
