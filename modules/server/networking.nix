{ config, ... }:
{
  # Wired via the USB-C→RJ45 dongle, Wi-Fi as a standing failover.
  #
  # No custom .network files: with networkd, NixOS's generic DHCP networks
  # already are the failover. Every physical Ethernet link (Type=ether, Kind=!*
  # — so not the containers' veths) gets route metric 1024, every Wi-Fi station
  # 1025. Both links stay up with their own address; the dongle wins while it has
  # carrier, and when it drops or re-enumerates its routes vanish and Wi-Fi
  # carries on. Nothing matches by name or MAC, so a replacement dongle just works.
  networking.useNetworkd = true;
  networking.useDHCP = true; # the default, but the failover above depends on it
  systemd.network.wait-online.anyInterface = true;

  # SSID and PSK both come from sops: an SSID in a public repo next to a real
  # name is a location lookup on WiGLE. Until the host key is enrolled (first
  # boot) the rendered file doesn't exist and wpa_supplicant fails to start;
  # wired is unaffected.
  networking.wireless = {
    enable = true;
    extraConfigFiles = [ config.sops.templates."wifi.conf".path ];
  };
  sops.secrets.wifi_ssid = { };
  sops.secrets.wifi_psk = { };
  sops.templates."wifi.conf" = {
    owner = "wpa_supplicant";
    restartUnits = [ "wpa_supplicant.service" ];
    content = ''
      network={
        ssid="${config.sops.placeholder.wifi_ssid}"
        psk="${config.sops.placeholder.wifi_psk}"
      }
    '';
  };
}
