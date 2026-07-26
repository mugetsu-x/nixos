# 08 — Media stack: what (if anything) relocates, and fold PLAN.md into the map

Parent: [map](../map.md)
Type: grilling
Status: resolved
Blocked by: —

## Question

The keystone (03) division-of-labour principle keeps the **media pipeline on the
NAS** as a storage-adjacent service (the arr stack is light; the data lives on
the NAS array; the Shield direct-plays so transcode rarely fires). This ticket
confirms that against the one real pull toward the laptop and then consolidates
the plan:

1. **Does Jellyfin/transcoding relocate to the laptop's RTX 3060?** From 01 the
   3060 does HEVC/H.264 encode (no AV1) — better than the Celeron's QuickSync,
   but the Shield direct-plays most content so transcode is rare. Decide: keep
   transcoding on the NAS (simpler, data-local) vs. move Jellyfin to the laptop
   to use the GPU. Default per the principle: **stays on the NAS**; justify any
   exception (e.g. lots of remote/off-Shield playback that forces transcode).

2. **Any arr component relocate?** Almost certainly no — the stack is light and
   wants to sit next to its storage. Confirm the whole pipeline stays on the NAS.

3. **Consolidate `PLAN.md` into this map.** Per the map's Notes: once 03 resolved,
   fold `PLAN.md`'s media detail (usenet, hardlink layout, phase-0 hardware,
   shopping list, access notes) into this map as its *media* section — merging
   the **final, laptop-aware** media decision, not the old laptop-blind one. This
   ticket produces that consolidated media section (or decides to keep `PLAN.md`
   standalone and just link it, if that reads cleaner).

Resolution names what stays vs. moves and delivers the consolidated media plan.

## Answer

Grilled the media decisions against the post-keystone architecture. The user
reopened more than the ticket's original scope — PLAN.md's *quality* decision too —
because "so much new information" (laptop, Tailscale, Immich 06, backups 05) had
accumulated. Triaged: some PLAN.md decisions rest on premises that genuinely
changed (placement, quality) and were re-grilled; the true internals (usenet vs.
torrents, provider choice) were untouched by any new fact and left settled.

**1. Does the media server / transcoding relocate to the laptop's RTX 3060? — NO.**
The decision hinged entirely on one variable: *does transcode fire routinely?* The
user first wanted remote phone playback (which, against 4K sources, forces heavy
transcode and pulled Jellyfin toward the GPU), then chose to **restrict playback to
same-network** to keep things simple. Same-network ⇒ direct-play dominates (Shield +
capable LAN devices decode 4K HEVC) ⇒ **data-locality wins**, so Jellyfin stays on
the NAS next to its data, co-located with the arr stack. Remote viewing is
**best-effort over Tailscale**; the RTX 3060 is the **documented escape hatch** —
the *only* trigger to move Jellyfin to the laptop is remote transcode becoming
routine. The rare same-network browser transcode runs on the Celeron QuickSync;
Shield direct-plays 4K HEVC natively.

**2. Does any arr component relocate? — NO.** The old "must be awake at 03:00"
reason is dead (the laptop is also 24/7), so placement now rests on **hardlink
locality**: Radarr imports by hardlinking `usenet/complete` → `media/` within the
single btrfs share; run over NFS from the laptop and the arr apps fall back to full
copies. Zero compute upside, and it's exactly the "light storage-adjacent service"
the keystone (03) left on the NAS.

**Bonus decision — quality (PLAN.md's "1080p default" broke):** the home theater is
4K. Chose **4K for both films and TV**, made safe by 05 (media is re-downloadable,
excluded from backup). The array is therefore a **rotating pool, not an archive** —
curate/delete first when it fills (re-downloads on demand); disk upgrades
(2→4→8 TB) are for real keep-set growth, not to avoid deleting.

**3. Consolidation.** PLAN.md is **kept standalone and updated laptop-aware** (not
folded into the map — the map is a decision *index*; PLAN.md is the execution
runbook). Additionally, per the destination ("a written architecture plan"),
assembled the whole-home capstone **[`ARCHITECTURE.md`](../ARCHITECTURE.md)** from
all 8 tickets: the workload→machine division, backup topology, and remote-access
approach, in one readable doc.

Assets: [`../ARCHITECTURE.md`](../ARCHITECTURE.md) (new), [`../PLAN.md`](../PLAN.md)
(updated). With this ticket closed the map has no open frontier and the
destination is reached.
