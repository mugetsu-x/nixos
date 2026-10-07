{ config, lib, ... }:
let
  port = 8082;

  # `href` is what the browser opens; a widget's `url` is fetched server-side
  # by Homepage, and every app is on the host network, so that is localhost.
  app = name: appPort: {
    href = "http://home-server:${toString appPort}";
    icon = "${name}.png";
    siteMonitor = "http://localhost:${toString appPort}";
  };
  withWidget =
    name: appPort: extra:
    app name appPort
    // {
      widget = {
        type = name;
        url = "http://localhost:${toString appPort}";
        key = "{{HOMEPAGE_VAR_${lib.toUpper name}_KEY}}";
      }
      // extra;
    };

  # Widget API keys: sops → one env file → `{{HOMEPAGE_VAR_<APP>_KEY}}` in the
  # generated YAML. Never a literal here, the repo is public.
  keyed = [
    "radarr"
    "sonarr"
    "sabnzbd"
    "jellyfin"
    "jellyseerr"
    "immich"
  ];
in
{
  # Start page for every service (nas/build/issues/16). Holds no data of its
  # own, so nothing for 13 to back up.
  services.homepage-dashboard = {
    enable = true;
    listenPort = port;
    openFirewall = true;
    # Every name it is reached by, or it refuses the request: LAN by name and
    # by both addresses (Ethernet .73, Wi-Fi .87), and the tailnet.
    allowedHosts = lib.concatMapStringsSep "," (h: "${h}:${toString port}") [
      "localhost"
      "127.0.0.1"
      "home-server"
      "192.168.0.73"
      "192.168.0.87"
      "home-server.tail2c2ea8.ts.net"
      "100.81.84.22"
    ];
    environmentFiles = [ config.sops.templates."homepage.env".path ];

    settings = {
      title = "home-server";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      hideVersion = true;
      layout = {
        Media = {
          style = "row";
          columns = 3;
        };
        Downloads = {
          style = "row";
          columns = 4;
        };
      };
    };

    services = [
      {
        Media = [
          {
            Jellyfin = withWidget "jellyfin" 8096 {
              enableBlocks = true;
              enableNowPlaying = true;
            };
          }
          { Jellyseerr = withWidget "jellyseerr" 5055 { }; }
          { Immich = withWidget "immich" 2283 { version = 2; }; }
        ];
      }
      {
        Downloads = [
          { SABnzbd = withWidget "sabnzbd" 8080 { }; }
          { Radarr = withWidget "radarr" 7878 { }; }
          { Sonarr = withWidget "sonarr" 8989 { }; }
          { Prowlarr = app "prowlarr" 9696; }
        ];
      }
    ];

    # Health at a glance only; alerting is 14. /data and /photos are one
    # volume on the NAS, so one disk entry covers both.
    widgets = [
      {
        resources = {
          label = "home-server";
          cpu = true;
          memory = true;
          cputemp = true;
          uptime = true;
          disk = "/";
          units = "metric";
        };
      }
      {
        resources = {
          label = "NAS";
          disk = "/data";
        };
      }
    ];
  };

  sops.secrets = lib.genAttrs (map (n: "${n}_api_key") keyed) (_: { });
  sops.templates."homepage.env" = {
    content = lib.concatMapStrings (
      n: "HOMEPAGE_VAR_${lib.toUpper n}_KEY=${config.sops.placeholder."${n}_api_key"}\n"
    ) keyed;
    restartUnits = [ "homepage-dashboard.service" ];
  };
}
