{ pkgs, ... }:
let
  nas = "192.168.0.70"; # DS420+ ("alexandria"), LAN — the exports allow only .73/.87

  # Every container sees these exact paths, so a hardlink import in the arr
  # stack stays a hardlink (usenet/complete and media/ live in one export).
  mountOpts = [
    "nfsvers=4.1"
    "hard" # never soft: a dropped NAS must stall I/O, not return errors
    "x-systemd.automount"
    "x-systemd.idle-timeout=0"
    "x-systemd.mount-timeout=30"
    "_netdev"
    "noatime"
  ];

  # restic (13) must call this before it snapshots anything. An unmounted
  # automount point is an empty directory: snapshotting it writes a near-empty
  # snapshot, and the next `forget --prune` ages out the real history.
  nasMountGuard = pkgs.writeShellApplication {
    name = "nas-mount-guard";
    runtimeInputs = [
      pkgs.util-linux
      pkgs.coreutils
    ];
    text = ''
      # usage: nas-mount-guard PATH...   exits non-zero unless each PATH is a live NFS mount
      [ "$#" -gt 0 ] || { echo "nas-mount-guard: no path given" >&2; exit 2; }
      for p in "$@"; do
        # Touch the path first: it triggers the automount, and a dead NAS
        # makes this stall/fail instead of reading the empty underlying dir.
        timeout 60 stat -t "$p/." >/dev/null 2>&1 || { echo "nas-mount-guard: $p unreachable" >&2; exit 1; }
        # The automount stacks an autofs entry under the real nfs4 one, so
        # check every mount on the path rather than picking one line.
        mounts=$(findmnt -rn -o FSTYPE,SOURCE --target "$p" 2>/dev/null || true)
        echo "$mounts" | grep -q "^nfs4 ${nas}:" || {
          echo "nas-mount-guard: $p is not a live NFS mount from ${nas} (saw: $mounts)" >&2; exit 1
        }
      done
    '';
  };
in
{
  boot.supportedFilesystems = [ "nfs" ];

  fileSystems."/data" = {
    device = "${nas}:/volume1/data";
    fsType = "nfs";
    options = mountOpts;
  };
  fileSystems."/photos" = {
    device = "${nas}:/volume1/photos";
    fsType = "nfs";
    options = mountOpts;
  };

  environment.systemPackages = [ nasMountGuard ];

  # Containers: podman, GPU via CDI. Each service orders itself on its mounts
  # with `unitConfig.RequiresMountsFor = [ "/data" ];` (09/11/12).
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
  hardware.nvidia-container-toolkit.enable = true;
}
