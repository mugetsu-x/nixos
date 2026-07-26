# 12 — Deploy Jellyfin + Jellyseerr on `home-server`

**What to build:** Jellyfin and Jellyseerr as `oci-containers` on **`home-server`**,
with the RTX 3060 passed in for NVENC and GPU tone mapping. Jellyfin serves
`/mnt/nas/data/media` over NFS; metadata and transcode cache live on local NVMe.

**Why this moved off the NAS, and why Plex is gone.** The original plan kept Jellyfin
on the NAS because "same-network playback ⇒ direct-play dominates," with Plex as a
proving-window safety net. Both parts failed:

- The Shield direct-plays 4K HEVC, but **every other client** — phones, tablets,
  browsers, other TVs — needs HDR→SDR tone mapping, which the J4025's UHD 600 cannot
  do in real time. Those clients didn't get a slow stream, they got a **broken** one.
- **Plex cannot hardware-transcode without a Plex Pass**, which we don't have. It was
  a safety net that couldn't serve the clients that motivated the change — and its
  library was scheduled for deletion anyway, so it protected nothing.

**Plex is retired outright.** It is not reinstalled on the rebuilt NAS.

**Prove it before the pipeline exists.** Don't wait for a usenet grab to discover the
GPU or the mount is misconfigured. Drop a handful of **open-licence 4K HDR test
files** (Blender's *Tears of Steel*, the standard Jellyfish HEVC bitstreams) into
`media/` and validate the hard parts on day one — this is what the deleted Plex
library used to (badly) provide.

**GPU note:** 6 GB of VRAM is shared with Immich ML ([09](09-deploy-immich.md)).
Expect contention during Immich's initial backlog; `MACHINE_LEARNING_MODEL_TTL` is
what keeps it manageable.

**Blocked by:** 08 (GPU + NFS foundation). The Jellyseerr request-flow criterion also
needs 11.

**Status:** ready-for-agent

- [ ] Jellyfin serving `/mnt/nas/data/media`; metadata + transcode cache on NVMe
- [ ] **NVENC verified in use** (`nvidia-smi` shows the encode session) — not silently software-transcoding
- [ ] **Shield direct-plays a 4K HEVC HDR title** (no transcode session opens)
- [ ] **A phone and a browser play the same title**, tone-mapped, smoothly — the case that motivated the move
- [ ] Proven against open-licence test files *before* any usenet grab exists
- [ ] Jellyseerr requests flow through to Radarr/Sonarr (needs 11)
- [ ] Jellyfin metadata/watch-history identified as backup scope for [13](13-restic-321-service.md)
- [ ] Plex confirmed absent from the rebuilt NAS

_Decision detail: [08](../../issues/08-media-relocation-and-plan-consolidation.md#answer--second-pass-2026-07-26)._
