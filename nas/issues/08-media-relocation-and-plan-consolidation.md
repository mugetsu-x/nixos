# 08 — Media stack: what (if anything) relocates, and fold PLAN.md into the map

Parent: [map](../map.md)
Type: grilling
Status: open
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
