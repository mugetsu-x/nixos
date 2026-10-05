{ ... }:

{
  # Written ahead of the install, so it has to evaluate in CI before the disk
  # exists: filesystems are mounted by *label* (set when partitioning — see the
  # runbook in nas/build/issues/06), not by UUID. After the install, fold in
  # anything extra `nixos-generate-config --show-hardware-config` lists for
  # kernel modules, but keep the by-label devices.
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  hardware.cpu.amd.updateMicrocode = true;
}
