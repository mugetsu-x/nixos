{ ... }:
{
  # Jellyfin + Jellyseerr (nas/build/issues/12). Host networking so Jellyseerr
  # reaches Jellyfin (and later Radarr/Sonarr from 11) on localhost; the library
  # is /data mounted at the same path as in every other container. Config and
  # transcode cache stay on local NVMe, never on NFS. Containers run as root:
  # the NAS maps every write to 1024:100 anyway.
  virtualisation.oci-containers.containers = {
    jellyfin = {
      image = "docker.io/jellyfin/jellyfin:10.11.0";
      autoStart = true;
      extraOptions = [
        "--network=host"
        "--device=nvidia.com/gpu=all" # CDI, from hardware.nvidia-container-toolkit
      ];
      volumes = [
        "/var/lib/jellyfin/config:/config"
        "/var/cache/jellyfin:/cache"
        "/data:/data"
      ];
      environment.TZ = "Europe/Vienna";
    };

    jellyseerr = {
      image = "docker.io/fallenbagel/jellyseerr:2.7.3";
      autoStart = true;
      extraOptions = [ "--network=host" ];
      volumes = [ "/var/lib/jellyseerr:/app/config" ];
      environment = {
        TZ = "Europe/Vienna";
        PORT = "5055";
      };
    };
  };

  # Never start against an unmounted /data: an empty library would make
  # Jellyfin forget everything it had indexed.
  systemd.services.podman-jellyfin.unitConfig.RequiresMountsFor = [ "/data" ];

  systemd.tmpfiles.rules = [
    "d /var/lib/jellyfin/config 0755 root root -"
    "d /var/cache/jellyfin 0755 root root -"
    "d /var/lib/jellyseerr 0755 root root -"
  ];

  # LAN clients (the Shield) and the tailnet; no public exposure, the router
  # forwards nothing.
  networking.firewall.allowedTCPPorts = [
    8096 # Jellyfin
    5055 # Jellyseerr
  ];
}
