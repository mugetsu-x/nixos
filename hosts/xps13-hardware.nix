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

  # The firmware caps the CPU at 1.9 GHz with turbo off, at 55 °C and on AC
  # (2026-11-23: `intel_pstate/no_turbo` = 1 from boot, and `scaling_max_freq`
  # would not go above 1.9 GHz even after writing 3.1). That is Dell's
  # power-supply throttling, most likely set off by the worn battery (57 % of
  # its design capacity). It reaches Linux in two ways, and both are undone
  # here:
  #   - the ACPI `_PPC` frequency limit: ignored by the kernel parameter. It
  #     can only be applied at boot.
  #   - turbo off: switched back on by the unit below, at boot and after each
  #     resume. It also raises every core's limit, which the kernel leaves at
  #     the old maximum when turbo comes back.
  # thermald and the CPU's own thermal limits stay in force, so this cannot
  # overheat it. If the battery drains while plugged in, the charger is too
  # weak for turbo: drop both.
  boot.kernelParams = [ "processor.ignore_ppc=1" ];
  systemd.services.cpu-turbo = {
    description = "Re-enable turbo boost disabled by the firmware";
    wantedBy = [
      "multi-user.target"
      "suspend.target"
    ];
    after = [ "suspend.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo
      for c in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
        cat "$c/cpuinfo_max_freq" > "$c/scaling_max_freq"
      done
    '';
  };

  # Hardware video decoding. Haswell predates the iHD driver (Broadwell and
  # newer), so it needs the older i965 one.
  hardware.graphics.extraPackages = [ pkgs.intel-vaapi-driver ];
  # Name it outright. Left to guess, libva tries iHD first, and through a
  # Wayland display it then fails on i965 too; over the DRM render node, which
  # Chrome and mpv use, the guess ends on i965 anyway. Check with
  # `vainfo --display drm --device /dev/dri/renderD128`.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "i965";
}
