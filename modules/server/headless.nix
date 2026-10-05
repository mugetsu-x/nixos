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

  # A closed lid doesn't necessarily cut the panel backlight; blank the console.
  boot.kernelParams = [ "consoleblank=60" ];
}
