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

  # Idle power needs nothing here: the open driver already does fine-grained
  # runtime D3 on this hybrid laptop, and the idle dGPU reads `suspended` (06,
  # measured 2026-10-06). Don't add powerManagement.finegrained/PRIME "to fix
  # it". nvidiaPersistenced would block D3, so it stays off. And `nvidia-smi`
  # itself wakes the GPU: read power/runtime_status in sysfs *before* running it.
}
