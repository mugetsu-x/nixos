{ config, ... }:
{
  # Compute only: CUDA for Immich ML, NVENC for Jellyfin (08 adds the container
  # toolkit). There is no display server — `videoDrivers` is just how NixOS
  # selects the kernel driver; services.xserver itself stays off.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = true; # Ampere GA106 supports the open modules
    modesetting.enable = true;
    nvidiaSettings = false;
  };

  # Idle power is deliberately left at the driver default until it is measured
  # on the box (06's checklist). This is a hybrid laptop: the panel hangs off the
  # Ryzen iGPU, so the desktop "headless EDID" penalty may not apply at all, and
  # the real lever is runtime D3 (powerManagement.finegrained + PRIME offload bus
  # IDs from lspci). nvidiaPersistenced would block exactly that, so it is off.
}
