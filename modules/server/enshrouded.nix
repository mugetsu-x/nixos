{ config, ... }:
let
  # The image's default, a uid/gid that exists nowhere else on the box.
  id = "4711";

  # Its own bridge, so nothing reaches it but the forwarded port — and it
  # reaches nothing of ours. See the isolation chain below.
  subnet = "10.89.77.0/24";
  gateway = "10.89.77.1";
in
{
  # Enshrouded 1.0 dedicated server. Keen ship it for Windows only; the image
  # runs it under GE-Proton and keeps it current with steamcmd. The image tag
  # pins only that wrapper — the game itself updates via UPDATE_CRON (and on
  # every start), which it has to: a client on a newer build can't join an
  # older server.
  #
  # The one service that is public. A1 gives this line a public IPv4 (asked
  # for, it was CGNAT before), and the router forwards UDP 15637 to the wired
  # address .73 — the query port is the only one the server listens on. Joining
  # takes a role password from sops.
  #
  # Temporary: remove all of it once nobody plays any more — see TODO.md.
  virtualisation.oci-containers.containers.enshrouded = {
    image = "docker.io/mornedhels/enshrouded-server:1.8.0";
    # Started by hand when someone wants to play (`enshrouded-up` on main-pc),
    # not at boot: idle it still keeps Wine busy on about half a core, and
    # while it is down the router forward points at nothing.
    autoStart = false;
    networks = [ "enshrouded" ];
    # A DNAT rule, not a listener: inbound goes through FORWARD, so the host
    # firewall needs no open port for it.
    ports = [ "15637:15637/udp" ];
    extraOptions = [
      # Time to write the world out before `podman stop` kills it; under the
      # unit's 120 s TimeoutStopSec.
      "--stop-timeout=90"
    ];
    # Game files, savegame/ and backups/ all live under here, on NVMe.
    volumes = [ "/var/lib/enshrouded:/opt/enshrouded" ];
    environmentFiles = [ config.sops.templates."enshrouded.env".path ];
    environment = {
      TZ = "Europe/Vienna";
      PUID = id;
      PGID = id;
      SERVER_NAME = "rennsemml"; # shown in the public server browser
      # About 2 Mbit/s of upload per player against a ~15 Mbit/s line, which
      # also carries Immich and Jellyfin over Tailscale.
      SERVER_SLOT_COUNT = "6";
      SERVER_ENABLE_TEXT_CHAT = "true";
      SERVER_ENABLE_VOICE_CHAT = "true";
      UPDATE_CRON = "*/30 * * * *";
      UPDATE_CHECK_PLAYERS = "true";
      BACKUP_CRON = "*/30 * * * *";
      BACKUP_MAX_COUNT = "48";

      SERVER_ROLE_0_NAME = "Admin";
      SERVER_ROLE_0_CAN_KICK_BAN = "true";
      SERVER_ROLE_0_CAN_ACCESS_INVENTORIES = "true";
      SERVER_ROLE_0_CAN_EDIT_WORLD = "true";
      SERVER_ROLE_0_CAN_EDIT_BASE = "true";
      SERVER_ROLE_0_CAN_EXTEND_BASE = "true";
      SERVER_ROLE_0_RESERVED_SLOTS = "1";

      SERVER_ROLE_1_NAME = "Friends";
      SERVER_ROLE_1_CAN_ACCESS_INVENTORIES = "true";
      SERVER_ROLE_1_CAN_EDIT_WORLD = "true";
      SERVER_ROLE_1_CAN_EDIT_BASE = "true";
      SERVER_ROLE_1_CAN_EXTEND_BASE = "true";
    };
  };

  # oci-containers attaches networks but doesn't create them.
  systemd.services.podman-network-enshrouded = {
    path = [ config.virtualisation.podman.package ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman network exists enshrouded ||
        podman network create --subnet ${subnet} --gateway ${gateway} \
          --interface-name enshrouded0 enshrouded
    '';
  };
  systemd.services.podman-enshrouded = {
    requires = [ "podman-network-enshrouded.service" ];
    after = [ "podman-network-enshrouded.service" ];
  };

  # aardvark-dns on the gateway is the container's only resolver; the host's
  # own upstream (the router) is a private address and blocked below.
  networking.firewall.interfaces.enshrouded0 = {
    allowedUDPPorts = [ 53 ];
    allowedTCPPorts = [ 53 ];
  };

  # Isolation. A bridge alone keeps the server off the host's loopback-only
  # services (Caddy's admin API, and lo is trusted, so Postgres, valkey and the
  # ML port too), but its traffic is masqueraded as .73 — and the NAS's NFS
  # exports trust exactly .73. So: no connection from the game to any private
  # or tailnet address, the host included. Replies to players who connected in
  # (LAN ones too) are ESTABLISHED and pass. In mangle, after conntrack and
  # before routing, where neither netavark nor the NixOS firewall writes, so
  # the order of their rules doesn't matter.
  networking.firewall.extraCommands = ''
    iptables -t mangle -D PREROUTING -s ${subnet} -j enshrouded-isolate 2>/dev/null || true
    iptables -t mangle -N enshrouded-isolate 2>/dev/null || true
    iptables -t mangle -F enshrouded-isolate
    iptables -t mangle -A enshrouded-isolate -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
    iptables -t mangle -A enshrouded-isolate -d ${gateway} -p udp --dport 53 -j RETURN
    iptables -t mangle -A enshrouded-isolate -d ${gateway} -p tcp --dport 53 -j RETURN
    for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.64.0.0/10 169.254.0.0/16 224.0.0.0/4; do
      iptables -t mangle -A enshrouded-isolate -d "$net" -j DROP
    done
    iptables -t mangle -A PREROUTING -s ${subnet} -j enshrouded-isolate
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t mangle -D PREROUTING -s ${subnet} -j enshrouded-isolate 2>/dev/null || true
    iptables -t mangle -F enshrouded-isolate 2>/dev/null || true
    iptables -t mangle -X enshrouded-isolate 2>/dev/null || true
  '';

  systemd.tmpfiles.rules = [ "d /var/lib/enshrouded 0755 ${id} ${id} -" ];

  # Read them with `sops -d secrets/home-server.yaml`. No restartUnits: that
  # would start the server on any rebuild that touches them; a changed
  # password applies on the next `enshrouded-up`.
  sops.secrets.enshrouded_admin_password = { };
  sops.secrets.enshrouded_friend_password = { };
  sops.templates."enshrouded.env".content = ''
    SERVER_ROLE_0_PASSWORD=${config.sops.placeholder.enshrouded_admin_password}
    SERVER_ROLE_1_PASSWORD=${config.sops.placeholder.enshrouded_friend_password}
  '';
}
