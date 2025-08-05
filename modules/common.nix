{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "Europe/Vienna";

  i18n.defaultLocale = "en_US.UTF-8";



  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  environment.systemPackages = with pkgs; [
    kitty
    google-chrome
    git
  ];

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
