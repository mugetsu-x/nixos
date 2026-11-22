{ ... }:

{
  # home-manager entrypoint for xps13, the work laptop. Same desktop as main-pc
  # (rennsemml.nix) without gaming and without Zed: Zed needs Vulkan, which on
  # this Haswell iGPU is the legacy, incomplete `hasvk` driver.
  home.username = "rennsemml";
  home.homeDirectory = "/home/rennsemml";
  # Compatibility marker for a fresh 26.05 install, not a version to "update".
  home.stateVersion = "26.05";

  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/wayland.nix
    ./modules/desktop-xps13.nix
    ./modules/services.nix
    ./modules/neovim.nix
    ./modules/chrome.nix
    ./modules/swayimg.nix
    ./modules/media.nix
    ./modules/dolphin.nix
    ./modules/theme.nix
    ./modules/pwas.nix
    ./modules/cli.nix
    ./modules/dev.nix
    ./modules/azure.nix
    ./modules/claude.nix
  ];
}
