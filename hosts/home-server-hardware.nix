{ ... }:

{
  # Kernel modules as `nixos-generate-config` detected them on the ThinkBook
  # (2026-10-05). Filesystems are mounted by *label*, not UUID, so this
  # evaluated in CI before the disk was partitioned. Reinstalling means
  # recreating the labels (runbook in nas/build/issues/06).
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "sdhci_pci"
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

  # On mains 24/7: cap the battery at ~60% (Lenovo "conservation mode", via
  # ideapad_acpi — ThinkBooks don't have thinkpad_acpi's thresholds). Set when
  # the driver binds rather than by tmpfiles, which can run before it loads.
  services.udev.extraRules = ''
    ACTION=="bind", SUBSYSTEM=="platform", DRIVER=="ideapad_acpi", ATTR{conservation_mode}="1"
  '';
}
