# 07 — File-sync / personal-cloud solution (hosted on the ThinkBook)

Parent: [map](../map.md)
Type: grilling
Status: open
Blocked by: —

## Question

Placement is settled by the keystone (03): **file-sync runs on the ThinkBook**
(compute/application layer). The open decision is *which solution*, driven by
what you actually need it to do:

- **Syncthing** — peer-to-peer folder sync, no server-of-record, no web UI for
  files, no sharing links. Lightweight, great for "keep these folders in sync
  across my devices." Weak for non-technical family or web access.
- **Nextcloud** — full personal cloud: web UI, mobile apps, file sharing links,
  calendar/contacts, but heavier (PHP + DB + cron) and more to maintain. Has a
  first-class NixOS module. Right choice if family members need a URL/app to
  reach files, or you want more than raw folder sync.
- **Other** (Seafile, ownCloud, plain SMB + a mobile client, etc.).

Consider: is this just *your* multi-device sync, or a **shared household**
service? Does it need to be reachable from outside the house (references remote
access, 04)? Where does the synced data live — laptop NVMe vs NAS mount (mirrors
the 06 storage question)?

Resolution names the tool, where its data lives, and any prerequisites.
