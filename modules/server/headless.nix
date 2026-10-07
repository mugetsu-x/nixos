{ ... }:
let
  # main-pc's key. Deploys (`nixos-rebuild --target-host root@home-server`)
  # and interactive logins both come from there.
  mainPcKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILUtqoLVMp0/T2rk+2UFX43a5qtEotXDBLFdYGB1Nzly walter@pariggers.com";
in
{
  # Key-only SSH. Root login exists only for deploys from main-pc. Its ed25519
  # host key is also the box's sops identity (modules/server/secrets.nix).
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

  # Lid closed, on a shelf, 24/7: nothing may suspend it.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # On battery (charger out, power cut), power off cleanly before it runs flat:
  # nothing restarts it after a flat battery, and a flat battery cuts Postgres
  # mid-write. 1 % ≈ 0.64 Wh, about a minute at full load (35.8 W measured under
  # the Immich import), so 10 % leaves ~10 min for a clean shutdown; at idle
  # (~2.4 W) it is hours. The default action, HybridSleep, can't run here: the
  # sleep targets above are disabled.
  services.upower = {
    enable = true;
    percentageLow = 30;
    percentageCritical = 15;
    percentageAction = 10;
    criticalPowerAction = "PowerOff";
  };
  # upower is D-Bus activated: it only starts when something asks it over D-Bus,
  # and on a headless box nothing does. Without this it isn't running after a
  # reboot, and the action above never fires.
  systemd.services.upower.wantedBy = [ "multi-user.target" ];

  # A closed lid doesn't necessarily cut the panel backlight; blank the console.
  boot.kernelParams = [ "consoleblank=60" ];
}
