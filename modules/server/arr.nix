{ ... }:
let
  # The NAS maps every NFS write to 1024:100 ("admin"), so running as that
  # user keeps ownership consistent on both sides.
  puid = "1024";
  pgid = "100";

  # /data is mounted at the same path in every container: SABnzbd writes
  # /data/usenet/complete, Radarr/Sonarr hardlink into /data/media. Config
  # (and SABnzbd's incomplete/, on NVMe) lives under /var/lib/<app>.
  arr = name: image: {
    image = "lscr.io/linuxserver/${name}:${image}";
    autoStart = true;
    extraOptions = [ "--network=host" ];
    volumes = [
      "/var/lib/${name}:/config"
      "/data:/data"
    ];
    environment = {
      PUID = puid;
      PGID = pgid;
      TZ = "Europe/Vienna";
    };
  };
in
{
  # Ports on the host network: SABnzbd 8080, Prowlarr 9696,
  # Radarr 7878, Sonarr 8989.
  virtualisation.oci-containers.containers = {
    sabnzbd = arr "sabnzbd" "5.1.3-ls275";
    prowlarr = arr "prowlarr" "2.6.5.5623-ls162";
    radarr = arr "radarr" "6.4.4.10685-ls319";
    sonarr = arr "sonarr" "4.0.20.3014-ls326";
  };

  systemd.services = builtins.listToAttrs (
    map
      (n: {
        name = "podman-${n}";
        value.unitConfig.RequiresMountsFor = [ "/data" ];
      })
      [
        "sabnzbd"
        "prowlarr"
        "radarr"
        "sonarr"
      ]
  );

  systemd.tmpfiles.rules = map (n: "d /var/lib/${n} 0755 ${puid} ${pgid} -") [
    "sabnzbd"
    "prowlarr"
    "radarr"
    "sonarr"
  ];

  # Usenet credentials: decrypted to /run/secrets only. They are entered into
  # SABnzbd / Prowlarr from there (never a literal in this repo); the apps keep
  # them in their own config under /var/lib, which 13 backs up.
  sops.secrets.eweka_username = { };
  sops.secrets.eweka_password = { };
  sops.secrets.nzbgeek_api_key = { };

  networking.firewall.allowedTCPPorts = [
    8080
    9696
    7878
    8989
  ];
}
