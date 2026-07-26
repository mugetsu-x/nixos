# 09 — Laptop container + GPU foundation

**What to build:** `home-server` ready to run GPU containers against NAS storage.
`nvidia-container-toolkit` + an oci-containers backend on the host; NAS media +
photo-originals **NFS-mounted**. Proven by a CUDA test container that enumerates
the RTX 3060. This is the substrate Immich (10) runs on.

**Blocked by:** 03 (home-server host), 05 (NAS NFS exports).

**Status:** ready-for-agent

- [ ] `nvidia-container-toolkit` working; a CUDA container enumerates the 3060
- [ ] NAS NFS exports (photo originals + media) mounted on `home-server`
- [ ] oci-containers backend configured

_Detail: [06](../../issues/06-immich-placement-migration.md) (host prereqs)._
