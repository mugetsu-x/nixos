{ config, ... }:
let
  # The image's default, a uid/gid that exists nowhere else on the box.
  id = "4711";
in
{
  # Enshrouded 1.0 dedicated server. Keen ship it for Windows only; the image
  # runs it under GE-Proton and keeps it current with steamcmd. The image tag
  # pins only that wrapper — the game itself updates via UPDATE_CRON, which it
  # has to: a client on a newer build can't join an older server.
  #
  # The one service that is public. A1 gives this line a public IPv4 (asked
  # for, it was CGNAT before), and the router forwards UDP 15637 to the wired
  # address .73 — the query port is the only one the server listens on. Joining
  # takes a role password from sops.
  virtualisation.oci-containers.containers.enshrouded = {
    image = "docker.io/mornedhels/enshrouded-server:1.8.0";
    # Started by hand when someone wants to play (`enshrouded-up` on main-pc),
    # not at boot: idle it still keeps Wine busy on about half a core, and
    # while it is down the router forward points at nothing.
    autoStart = false;
    extraOptions = [
      "--network=host"
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

  systemd.tmpfiles.rules = [ "d /var/lib/enshrouded 0755 ${id} ${id} -" ];

  # Read them with `sops -d secrets/home-server.yaml`.
  sops.secrets.enshrouded_admin_password = { };
  sops.secrets.enshrouded_friend_password = { };
  sops.templates."enshrouded.env" = {
    restartUnits = [ "podman-enshrouded.service" ];
    content = ''
      SERVER_ROLE_0_PASSWORD=${config.sops.placeholder.enshrouded_admin_password}
      SERVER_ROLE_1_PASSWORD=${config.sops.placeholder.enshrouded_friend_password}
    '';
  };

  networking.firewall.allowedUDPPorts = [ 15637 ];
}
