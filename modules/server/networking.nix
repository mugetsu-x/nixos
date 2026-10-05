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

  # Identify to DHCP by MAC, not networkd's default DUID. With the DUID, the A1
  # router can't reserve an address for the box (and the installer, which sent
  # the MAC, got a different one). The NAS's NFS rules are pinned to these two
  # addresses, so they have to be reservations.
  systemd.network.networks."99-ethernet-default-dhcp".dhcpV4Config.ClientIdentifier = "mac";
  # Both links sit on the same subnet. By default Linux answers ARP for any of
  # its addresses on every interface, so the router saw .73 *and* .87 behind
  # each MAC — and refuses to bind an IP to a device with two. Answer only on
  # the interface that owns the address, and source ARP from it.
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.arp_ignore" = 1;
    "net.ipv4.conf.all.arp_announce" = 2;
  };

  systemd.network.networks."99-wireless-client-dhcp".dhcpV4Config = {
    ClientIdentifier = "mac";
    # The router merges leases that send the same hostname into one entry with
    # two IPs, and won't let you bind an IP on such an entry. A distinct name
    # gives Wi-Fi its own, reservable entry.
    Hostname = "home-server-wifi";
  };

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
