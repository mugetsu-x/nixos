# 05 — Backup strategy: 3-2-1 topology and offsite target for the photos

Parent: [map](../map.md)
Type: grilling
Status: open
Blocked by: —

## Question

The highest-stakes decision in the map: ~950 GB of **irreplaceable family
photos** currently exist as a single copy on the NAS's RAID 5 array. RAID is not
a backup. `nas/PLAN.md` even flags that its phase-0 array expansion runs degraded
and wants the photos backed up off the NAS *first* — so this is also a near-term
blocker, not just future architecture.

Decide the **3-2-1 topology**:

- **Second on-site copy:** where does copy #2 live? (External USB disk on the NAS?
  The laptop's disks? A second machine?) The laptop-as-target option references
  the keystone (03) but the *principle* — that a second local copy must exist —
  can be settled now.
- **Offsite copy #3:** cloud (Backblaze B2 / Storj / rsync.net) vs. a physical
  disk rotated to another location. What budget, and encrypted how?
- **Tooling & scope:** what runs the backups (Synology Hyper Backup, restic,
  borg, Syncthing?), how often, versioned/immutable against ransomware, and
  which datasets beyond photos are included.
- **Restore test:** how you'll verify a restore actually works.

Resolution names the topology, the tools, the offsite target, and an immediate
"get the photos to a second copy before any risky NAS operation" step.
