{ ... }:
let
  # home-server's wired + Wi-Fi addresses (bound on the router, nas/build 06).
  homeServer = [
    "192.168.0.73"
    "192.168.0.87"
  ];
in
{
  # Spare-GPU ML worker for home-server's Immich (nas/build/issues/09, optional
  # box). Immich takes a list of ML URLs and falls back in order: this one is
  # listed first in Admin → Machine Learning, the 3060's own container second,
  # so with the PC off nothing breaks. Worth it for the import backlog (10) and
  # model swaps, not day-to-day.
  #
  # Not started at boot — it would sit on the 3080's VRAM while gaming:
  #   sudo systemctl start docker-immich-machine-learning   # stop when done
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.immich-machine-learning = {
    image = "ghcr.io/immich-app/immich-machine-learning:${import ./server/immich-version.nix}-cuda";
    autoStart = false;
    extraOptions = [
      # Host networking, not `-p 3003:3003`: Docker's published ports bypass
      # the NixOS firewall entirely, and this port has no auth.
      "--network=host"
      "--device=nvidia.com/gpu=all" # CDI, from hardware.nvidia-container-toolkit
    ];
    volumes = [ "/var/cache/immich-ml:/cache" ];
    environment.MACHINE_LEARNING_MODEL_TTL = "300";
  };

  systemd.tmpfiles.rules = [ "d /var/cache/immich-ml 0755 root root -" ];

  # Port 3003 for home-server only (IPv4; the URL in Immich uses the address).
  networking.firewall.extraCommands = builtins.concatStringsSep "\n" (
    map (ip: "iptables -A nixos-fw -p tcp --dport 3003 -s ${ip} -j nixos-fw-accept") homeServer
  );
}
