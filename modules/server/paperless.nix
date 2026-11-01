{ config, lib, ... }:
let
  cfg = config.services.paperless;
in
{
  # Paperless-ngx (nas/build/issues/15). Native module, not a container: no
  # CUDA here, so nothing needs the image. Same split as Immich: the
  # `documents` export holds the originals, the OCR'd archive PDFs and the
  # consume folder; Postgres, Redis and the search index stay on the NVMe
  # under /var/lib (a DB on NFS is a corruption risk).
  services.paperless = {
    enable = true;
    address = "0.0.0.0";
    port = 28981;
    mediaDir = "/documents/media";
    # A scanner or PC drops files here over SMB; Paperless deletes them once
    # they are consumed.
    consumptionDir = "/documents/consume";
    database.createLocally = true;
    # The superuser. Anja gets her own account in the UI; both see everything.
    passwordFile = config.sops.secrets.paperless_admin_password.path;

    settings = {
      PAPERLESS_ADMIN_USER = "walter";
      # Austrian paperwork is German. The module builds tesseract with exactly
      # these languages.
      PAPERLESS_OCR_LANGUAGE = "deu+eng";
      # Set before the first document: without it the archive on disk is
      # 0000001.pdf…, unreadable without Paperless. Changing it later renames
      # every file.
      PAPERLESS_FILENAME_FORMAT = "{{ created_year }}/{{ correspondent }}/{{ created }} {{ title }}";
      PAPERLESS_FILENAME_FORMAT_REMOVE_NONE = true;
      # inotify sees nothing on NFS: a file the scanner writes via the NAS
      # never raises an event here. Poll instead (seconds).
      PAPERLESS_CONSUMER_POLLING = 60;
      PAPERLESS_CONSUMER_RECURSIVE = true;
    };
  };

  # Immich's Postgres container already binds 0.0.0.0:5432 on the host
  # network. Paperless talks to this one over /run/postgresql, so it needs
  # no TCP listener at all.
  services.postgresql.settings.listen_addresses = lib.mkForce "";

  # The module's tmpfiles rules also cover mediaDir and consumptionDir. On an
  # automount, tmpfiles at early boot would trigger the NFS mount before the
  # network is up. Keep only the local dataDir; the two NAS folders were made
  # once by hand. RequiresMountsFor (below) still keeps Paperless from
  # starting against an unmounted /documents.
  systemd.tmpfiles.settings."10-paperless" = lib.mkForce {
    ${cfg.dataDir}.d = {
      inherit (cfg) user;
      group = config.users.users.${cfg.user}.group;
    };
  };

  # The module orders only the scheduler on its directories. The task queue is
  # what writes the originals, so make every unit wait for /documents.
  systemd.services =
    lib.genAttrs [ "paperless-task-queue" "paperless-consumer" "paperless-web" ]
      (_: {
        unitConfig.RequiresMountsFor = [ "/documents" ];
      });

  # Nightly pg_dump to /var/backup/postgresql, for 13 to back up. Never a
  # file-level snapshot of the live DB.
  services.postgresqlBackup = {
    enable = true;
    databases = [ "paperless" ];
  };

  # Read by the module via LoadCredential, so root-owned is fine.
  sops.secrets.paperless_admin_password = { };

  networking.firewall.allowedTCPPorts = [ cfg.port ];
}
