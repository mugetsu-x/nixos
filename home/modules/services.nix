{ pkgs, ... }:

let
  # script for auto-connecting trusted BT devices (moved here; identical logic)
  btAutoconnect = pkgs.writeShellScript "bt-autoconnect.sh" ''
    set -euo pipefail
    sleep 5
    for mac in $(${pkgs.bluez}/bin/bluetoothctl devices Paired | awk '{print $2}'); do
      if ${pkgs.bluez}/bin/bluetoothctl info "$mac" | grep -q "Trusted: yes"; then
        if ! ${pkgs.bluez}/bin/bluetoothctl info "$mac" | grep -q "Connected: yes"; then
          echo "Connecting $mac"
          ${pkgs.bluez}/bin/bluetoothctl connect "$mac" || true
        fi
      fi
    done
  '';
in
{
  # Clipboard history daemon
  systemd.user.services.cliphist-store = {
    Unit = {
      Description = "Wayland clipboard history daemon";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  # Auto-connect Bluetooth trusted devices
  systemd.user.services.bt-autoconnect = {
    Unit = {
      Description = "Auto-connect trusted Bluetooth devices";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = btAutoconnect;
    };
    Install = { WantedBy = [ "default.target" ]; };
  };
}
