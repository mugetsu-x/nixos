{
  config,
  lib,
  pkgs,
  nix-claude-code,
  pkgs-unstable,
  ...
}:
{
  imports = [
    ../modules/hardware.nix
    ../modules/base.nix
    ../modules/nvidia.nix
    ../modules/common.nix
    ../modules/login.nix
    ../modules/gaming.nix
    ../modules/nix-tools.nix
    ../modules/keyring.nix
    ../modules/secrets.nix
    ../modules/immich-ml.nix
  ];
  networking.hostName = "main-pc";
  # Compatibility marker, not a version to "update". See CLAUDE.md.
  system.stateVersion = "25.05";

  services.printing.enable = true;

  home-manager.backupFileExtension = "hm-bak";
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  # `useGlobalPkgs` means home-manager modules get the stable `pkgs`. Zed needs a
  # newer one than 25.05 carries, so hand the unstable set through separately.
  home-manager.extraSpecialArgs = { inherit pkgs-unstable; };
  hardware.printers = {
    ensurePrinters = [
      {
        name = "brother-hl-l8260cdw";
        description = "Brother HL-L8260CDW (Wi-Fi)";
        deviceUri = "ipp://192.168.0.9:631/ipp/print";
        model = "everywhere"; # IPP Everywhere (driverless)
        # ppdOptions = { Duplex = "DuplexNoTumble"; };  # optional tweaks
      }
    ];

    ensureDefaultPrinter = "brother-hl-l8260cdw";
  };
  # `model = "everywhere"` makes lpadmin query the printer, so if it is off at
  # boot the unit fails once and CUPS is left with no queue. Retry until the
  # printer shows up. `simple` rather than upstream's `oneshot`, because
  # multi-user.target is ordered after this unit and would otherwise wait on it.
  systemd.services.ensure-printers = {
    startLimitIntervalSec = 0;
    serviceConfig = {
      Type = lib.mkForce "simple";
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };

  # Hyprland
  programs.hyprland.enable = true;
  # One local patch, for the Wacom tablet: Hyprland sends wl_pointer.motion next
  # to zwp_tablet_tool_v2.motion while the pen hovers, so a tablet-aware client
  # sees a mouse and a pen at once. Microsoft Whiteboard (Chrome) then switches
  # to its mouse tool after every stroke and the next stroke does not draw.
  # The patch drops the pointer motion for a client that has the pen in
  # proximity, as sway and KWin do. Cost: Hyprland is compiled locally instead
  # of fetched from the cache, and a Hyprland bump may stop the patch applying
  # (the build fails loudly; rebase or drop it).
  programs.hyprland.package = pkgs.hyprland.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ../modules/patches/hyprland-tablet-no-pointer-motion.patch
      # Makes the pen buttons bindable (mouse:331 / mouse:332 in hyprland.conf);
      # stock Hyprland only forwards them to the client.
      ../modules/patches/hyprland-tablet-button-binds.patch
    ];
  });

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

  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  users.users.rennsemml.extraGroups = [ "docker" ];

  # --- CLAUDE CODE INSTALLATION ---
  # Pull the package directly from the flake input
  environment.systemPackages = [
    nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Home Manager user config
  home-manager.users.rennsemml = import ../home/rennsemml.nix;
}
