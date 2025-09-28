{ config, pkgs, ... }: {
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  security.pam.services.hyprlock = { };
}

