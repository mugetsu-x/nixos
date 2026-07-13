{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "main-pc";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";
  nixpkgs.config.allowUnfree = true;

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # kitty lives in home/modules/packages.nix; git stays system-wide so it works as root.
  environment.systemPackages = with pkgs; [ git ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  users.users.rennsemml = {
    isNormalUser = true;
    description = "rennsemml";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  programs.dconf.enable = true;

  # Bluetooth stack
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.linux-firmware ];
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = { Experimental = true; };
      Policy = { AutoEnable = true; };
    };
  };

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "altgr-intl";

  services.blueman.enable = true;

  # udiskie (home/modules/services.nix) talks to the UDisks2 D-Bus service, which
  # nothing else pulls in since we are not running a full desktop environment.
  services.udisks2.enable = true;

  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  security.rtkit.enable = true;

  system.stateVersion = "25.05";
}
