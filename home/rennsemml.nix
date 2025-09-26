{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  home.username = "rennsemml";
  home.homeDirectory = "/home/rennsemml";
  home.stateVersion = "25.05";

  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/wayland.nix
    ./modules/services.nix
    # (LazyVim module can be added later when we do it)
  ];
}
