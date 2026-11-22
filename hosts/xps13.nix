{
  pkgs,
  nix-claude-code,
  ...
}:
let
  # main-pc's key, the same one home-server trusts (modules/server/headless.nix).
  mainPcKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILUtqoLVMp0/T2rk+2UFX43a5qtEotXDBLFdYGB1Nzly walter@pariggers.com";
in
{
  # The work laptop: main-pc's desktop without NVIDIA, gaming, Docker and Zed.
  imports = [
    ./xps13-hardware.nix
    ../modules/base.nix
    ../modules/common.nix
    ../modules/hyprland.nix
    ../modules/login.nix
    ../modules/laptop.nix
    ../modules/nix-tools.nix
    ../modules/keyring.nix
  ];
  networking.hostName = "xps13";
  # Compatibility marker for a fresh 26.05 install, not a version to "update".
  system.stateVersion = "26.05";

  # Key-only SSH, reachable from main-pc alone: for setting the laptop up and
  # helping it from there. Root login exists for the same reason as on
  # home-server (`nixos-rebuild --target-host root@xps13`).
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [ mainPcKey ];
  users.users.rennsemml.openssh.authorizedKeys.keys = [ mainPcKey ];

  home-manager.backupFileExtension = "hm-bak";
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.rennsemml = import ../home/xps13.nix;

  # Claude Code, from the same flake input as on main-pc.
  environment.systemPackages = [
    nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
