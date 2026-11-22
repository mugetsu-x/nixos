{ ... }:

{
  # What a battery-powered machine needs on top of common.nix. Brightness keys,
  # touchpad and the waybar battery module are user-level (home/modules/
  # desktop-xps13.nix and home/dotfiles/hosts/xps13/).

  # Power profiles (power-saver / balanced / performance), switched with
  # `powerprofilesctl`. Chosen over TLP for having nothing to tune.
  services.power-profiles-daemon.enable = true;
  # Intel's thermal daemon: throttles before the firmware's hard limits do.
  services.thermald.enable = true;

  # Battery state over D-Bus. With no disk swap there is nothing to hibernate
  # to, so the default critical action (HybridSleep) cannot work; power off
  # cleanly at 5 % instead of dying mid-write.
  services.upower = {
    enable = true;
    percentageLow = 20;
    percentageCritical = 10;
    percentageAction = 5;
    criticalPowerAction = "PowerOff";
  };
  # upower is D-Bus activated and nothing in this desktop asks it anything
  # (waybar's battery module reads sysfs), so without this it is not running
  # and the power-off above never fires. Same fix as on home-server.
  systemd.services.upower.wantedBy = [ "multi-user.target" ];

  # Compressed swap in RAM. The only swap there is: it absorbs memory peaks
  # (Teams + Figma) without a swap partition inside the LUKS volume.
  zramSwap.enable = true;

  # Weekly TRIM; reaches the SSD because the LUKS volume allows discards.
  services.fstrim.enable = true;

  # Closing the lid suspends (logind's default); hypridle locks before sleep.
}
