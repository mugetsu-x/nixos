{ config, pkgs, ... }:

{
  home.username = "rennsemml";
  home.homeDirectory = "/home/rennsemml";
  home.stateVersion = "25.05";

  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/wayland.nix
    ./modules/services.nix
    ./modules/neovim-lazyvim.nix
    ./modules/chrome.nix
    ./modules/theme.nix
    ./modules/pwas.nix
    ./modules/gaming.nix
    ./modules/cli.nix
    ./modules/dev.nix
    ./modules/zed.nix
  ];
}
