{ pkgs, ... }:

{
  # Shared by every host. Anything desktop-only belongs in common.nix (main-pc);
  # hostName and system.stateVersion live in each hosts/<name>.nix.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";
  nixpkgs.config.allowUnfree = true;

  # The console follows the xkb layout, so a server console types like main-pc.
  # Why altgr-intl and how umlauts reach it: see the QMK note in common.nix.
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "altgr-intl";

  # git stays system-wide so it works as root.
  environment.systemPackages = with pkgs; [ git ];

  users.users.rennsemml = {
    isNormalUser = true;
    description = "rennsemml";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  hardware.enableRedistributableFirmware = true;
}
