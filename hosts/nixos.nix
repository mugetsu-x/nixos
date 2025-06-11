# /etc/nixos/hosts/nixos.nix
# This is your main NixOS system configuration, extracted from flake.nix
# Everything system-level (boot, networking, services, packages) goes here

{ config, pkgs, ... }:

{

  imports = [
    ../hardware-configuration.nix
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Vienna";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_AT.UTF-8";
    LC_IDENTIFICATION = "de_AT.UTF-8";
    LC_MEASUREMENT = "de_AT.UTF-8";
    LC_MONETARY = "de_AT.UTF-8";
    LC_NAME = "de_AT.UTF-8";
    LC_NUMERIC = "de_AT.UTF-8";
    LC_PAPER = "de_AT.UTF-8";
    LC_TELEPHONE = "de_AT.UTF-8";
    LC_TIME = "de_AT.UTF-8";
  };

  services.xserver.enable = false;
  services.xserver.xkb.layout = "us";

  services.dbus.enable = true;
  services.tlp.enable = true;
  services.pulseaudio.enable = false;
  hardware.bluetooth.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  programs.zsh.enable = true;
  programs.firefox.enable = true;
  programs.hyprland.enable = true;

  users.users.honswurst = {
    isNormalUser = true;
    description = "Walter";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  # System-level packages only (moved user apps to home.nix)
  environment.systemPackages = with pkgs; [
    tlp
    brightnessctl
    acpi
  ];

  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    image/png=swayimg.desktop
    image/jpeg=swayimg.desktop
    image/jpg=swayimg.desktop
    image/gif=swayimg.desktop
    image/bmp=swayimg.desktop
    image/webp=swayimg.desktop
  '';

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.05";
}
