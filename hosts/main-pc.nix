{ config, pkgs, nix-claude-code, ... }: {
  imports = [
    ../modules/hardware.nix
    ../modules/nvidia.nix
    ../modules/common.nix
    ../modules/login.nix
    ../modules/gaming.nix
    ../modules/nix-tools.nix
  ];
  services.printing.enable = true;

  home-manager.backupFileExtension = "hm-bak";
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
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

  # --- CLAUDE CODE INSTALLATION ---
  # Pull the package directly from the flake input
  environment.systemPackages =
    [ nix-claude-code.packages.${pkgs.system}.default ];

  # Home Manager user config
  home-manager.users.rennsemml = import ../home/rennsemml.nix;
}
