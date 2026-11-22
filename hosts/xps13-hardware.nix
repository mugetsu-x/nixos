{ pkgs, ... }:

{
  # Dell XPS 13 9333 (2013, Haswell): i7-4510U, 8 GB soldered, 512 GB mSATA,
  # Intel 7260 Wi-Fi + Bluetooth, 1080p touch panel. Kernel modules as
  # `nixos-generate-config` detected them (2026-11-22).
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  # The whole root is one LUKS2 volume; only /boot (kernels, initrd) is in the
  # clear. The passphrase is asked once at boot, and greetd's autologin
  # (modules/login.nix) then goes straight to Hyprland. Everything is found by
  # label, so a reinstall only has to recreate the labels:
  #   GPT partition label `cryptroot` (the LUKS partition)
  #   ext4 label `nixos` inside it, vfat label `BOOT` on the ESP
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-partlabel/cryptroot";
    # Pass TRIM through to the SSD. It leaks which blocks are unused, an
    # accepted trade for keeping an old mSATA drive healthy.
    allowDiscards = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  hardware.cpu.intel.updateMicrocode = true;

  # Hardware video decoding. Haswell predates the iHD driver (Broadwell and
  # newer), so it needs the older i965 one.
  hardware.graphics.extraPackages = [ pkgs.intel-vaapi-driver ];
}
