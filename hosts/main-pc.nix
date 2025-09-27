{ config, pkgs, home-manager, ... }: {
  imports = [
    ../modules/hardware.nix
    ../modules/nvidia.nix
    ../modules/common.nix
    ../modules/login.nix
    home-manager.nixosModules.home-manager
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
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  virtualisation.docker.enable = true;
  users.users.rennsemml.extraGroups = [ "docker" ];

  # Home Manager user config
  home-manager.users.rennsemml = import ../home/rennsemml.nix;
}
