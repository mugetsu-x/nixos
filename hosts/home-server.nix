{ ... }:
{
  # Lenovo ThinkBook 16p Gen 2 (20YM): Ryzen 9 5900HX, RTX 3060 Laptop 6 GB,
  # 32 GB. Headless and lid-closed; runs every service, the NAS only stores.
  # Plan: nas/ARCHITECTURE.md. Install + deploy: nas/build/issues/06.
  imports = [
    ./home-server-hardware.nix
    ../modules/base.nix
    ../modules/server/headless.nix
    ../modules/server/networking.nix
    ../modules/server/nvidia.nix
    ../modules/server/secrets.nix
  ];

  networking.hostName = "home-server";
  # Installed fresh on 26.05. A compatibility marker, never bump it.
  system.stateVersion = "26.05";
}
