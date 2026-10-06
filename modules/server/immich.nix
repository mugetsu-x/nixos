{ config, ... }:
let
  # Server and ML must run the same version. Never `:release`: Immich ships
  # breaking DB migrations, sometimes ones that need stepped upgrades — read the
  # release notes before bumping. Postgres and valkey are digest-pinned exactly
  # as in that release's docker-compose.yml; take them from the new one on bump.
  version = "v3.2.4";

  # Host networking, like the rest of home-server. The images' default
  # hostnames ("database", "redis", "immich-machine-learning") are pointed at
  # loopback, so no Immich setting has to change. Postgres, valkey and the ML
  # port (no auth) stay closed in the firewall on the LAN and the tailnet.
  localHosts = map (h: "--add-host=${h}:127.0.0.1") [
    "database"
    "redis"
    "immich-machine-learning"
  ];

  db = {
    DB_USERNAME = "postgres";
    DB_DATABASE_NAME = "immich";
  };
in
{
  # Immich (nas/build/issues/09). The `photos` export *is* the library: Immich's
  # /data is /photos, so upload/, library/, profile/ and backups/ (the nightly
  # DB dumps) land on the NAS. Local NVMe gets the hot path, which must never
  # cross the LAN: thumbs/, encoded-video/ and the model cache under /var/cache
  # (all regenerable), and Postgres under /var/lib (a DB on NFS is a corruption
  # risk). Containers run as root: the NAS maps every write to 1024:100 anyway.
  virtualisation.oci-containers.containers = {
    immich-server = {
      image = "ghcr.io/immich-app/immich-server:${version}";
      autoStart = true;
      dependsOn = [
        "immich-postgres"
        "immich-redis"
      ];
      extraOptions = [ "--network=host" ] ++ localHosts;
      volumes = [
        "/photos:/data"
        "/var/cache/immich/thumbs:/data/thumbs"
        "/var/cache/immich/encoded-video:/data/encoded-video"
      ];
      environmentFiles = [ config.sops.templates."immich.env".path ];
      environment = db // {
        TZ = "Europe/Vienna";
      };
    };

    immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:${version}-cuda";
      autoStart = true;
      extraOptions = [
        "--network=host"
        "--device=nvidia.com/gpu=all" # CDI, from hardware.nvidia-container-toolkit
      ];
      volumes = [ "/var/cache/immich/model-cache:/cache" ];
      environment = {
        TZ = "Europe/Vienna";
        # Unload idle models (seconds): the 3060's 6 GB is shared with
        # Jellyfin's NVENC, and an idle dGPU drops to runtime D3.
        MACHINE_LEARNING_MODEL_TTL = "300";
      };
    };

    immich-redis = {
      image = "docker.io/valkey/valkey:9@sha256:70739f85ad2ee01a726a965584a0f94895f01b0c60b3cc8b0aeef11eaa6888cf";
      autoStart = true;
      extraOptions = [ "--network=host" ];
    };

    immich-postgres = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      autoStart = true;
      extraOptions = [
        "--network=host"
        "--shm-size=128m"
      ];
      volumes = [ "/var/lib/immich/postgres:/var/lib/postgresql/data" ];
      environmentFiles = [ config.sops.templates."immich.env".path ];
      environment = {
        POSTGRES_USER = db.DB_USERNAME;
        POSTGRES_DB = db.DB_DATABASE_NAME;
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
    };
  };

  # Never start against an unmounted /photos: Immich would write new uploads
  # into the empty mount point on the NVMe and report the library as missing.
  systemd.services.podman-immich-server.unitConfig.RequiresMountsFor = [ "/photos" ];

  # One file for both containers: the server reads DB_PASSWORD, Postgres
  # POSTGRES_PASSWORD (honoured only at initdb — changing the secret later
  # needs an ALTER USER too). Immich wants A-Za-z0-9 only.
  sops.secrets.immich_db_password = { };
  sops.templates."immich.env".content = ''
    DB_PASSWORD=${config.sops.placeholder.immich_db_password}
    POSTGRES_PASSWORD=${config.sops.placeholder.immich_db_password}
  '';

  systemd.tmpfiles.rules = [
    "d /var/cache/immich/thumbs 0755 root root -"
    "d /var/lib/immich/postgres 0700 root root -"
    "d /var/cache/immich/encoded-video 0755 root root -"
    "d /var/cache/immich/model-cache 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 2283 ];
}
