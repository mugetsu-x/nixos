# 01 — Establish the ThinkPad's real specs and whether 24/7 headless is acceptable

Parent: [map](../map.md)
Type: grilling
Status: resolved
Assignee: Walter (claimed 2026-07-26)
Blocked by: —

## Question

Two things the keystone (03) can't be decided without:

1. **What is this ThinkPad, exactly?** The specific unit's CPU, RAM (and max),
   dGPU (model + VRAM — matters for Immich ML and any video transcoding),
   internal storage (size, NVMe slots free), and NIC (2.5GbE?). "16p Gen 2"
   narrows the model class (research 02 fills the general picture), but only you
   can read off *this* machine's config.

2. **Is running it 24/7, headless, at home acceptable?** Where would it physically
   live (noise/heat near living space?), is the electricity cost tolerable
   (idle-watts from 02 × your kWh price), lid-closed operation, and is its
   battery effectively a built-in UPS you're happy to rely on? Or do you only
   want it powered on when needed (which pushes toward "secondary node", not
   "always-on server")?

Resolution records the concrete spec sheet and a clear yes/no/conditional on
always-on operation. This is HITL — it needs your answers, not a guess.

## Answer

Resolved 2026-07-26 via `/grilling`, specs read off the unit (Windows 11
`Get-CimInstance`).

**Major correction to research 02:** the machine is **NOT a ThinkPad P16 Gen 2**.
It is a **Lenovo ThinkBook 16p Gen 2 (type 20YM, S/N PF3PTLZF)** — a consumer
creator/gaming laptop — with an **AMD** CPU and a **consumer GeForce** GPU, not
the Intel-HX + professional-RTX-Ada machine 02 assumed. Three of 02's GPU
conclusions therefore **do not hold** (see below). See the correction banner now
at the top of `research/thinkpad-p16g2-home-server.md`.

### Spec sheet (the real unit)

| | |
|---|---|
| **Model** | Lenovo ThinkBook 16p Gen 2, type **20YM** (S/N PF3PTLZF) |
| **CPU** | AMD **Ryzen 9 5900HX** — 8c/16t, Zen 3, 45 W class |
| **GPU** | NVIDIA **GeForce RTX 3060 Laptop, 6 GB** (Ampere GA106). CUDA ✓, NVENC H.264/HEVC ✓, **AV1 encode ✗** (AV1 *decode* ✓) |
| **RAM** | **32 GB** DDR4‑3200 SO‑DIMM = 2×16 GB (Samsung + Micron). **Both slots full** → expansion is *replace*, not add; 2×32 = 64 GB is the ceiling |
| **Storage** | 1× **WD SN730 1 TB** NVMe. 20YM has a 2nd M.2 2280 slot **almost certainly free** (only one drive present) — confirm by peeking; it's the key fact for ticket 05 |
| **NIC** | **Wi‑Fi only, no RJ‑45**. USB‑C/TB Ethernet dongle on hand |

### How this changes 02's GPU claims

| 02 claimed (pro Ada card) | RTX 3060 Laptop reality |
|---|---|
| 8th-gen NVENC with **AV1 encode** | 7th-gen NVENC — H.264/HEVC only, **no AV1 encode** (AV1 decode ✓) |
| **No** NVENC concurrent-session cap | GeForce cap (historically 3, raised to 8 by driver; patchable) |
| 8–16 GB VRAM | **6 GB** |

**The everyday value case survives:** 02 itself said the real win is *Immich ML*,
not media transcode, and 6 GB of CUDA-capable Ampere runs Immich's CLIP +
face-detection models comfortably. Since the Shield direct-plays, missing AV1
encode barely matters. The 5900HX is a capable 8-core server CPU. So the machine
is still a strong compute node — for *Immich ML + headroom*, not for the
Ada/AV1/pro-card reasons 02 wrote down.

### Always-on verdict: **YES, acceptable** (conditional)

- Runs 24/7 headless, **lid closed**, placed **out of the immediate desk/sleeping
  space** (shelf / cupboard / utility corner). User confirmed acceptable.
- **Electricity:** at **€0.355/kWh**, ~**€62/yr** at 20 W idle (with the EDID idle
  fix), rising to ~**€93/yr** at 30 W without it. ≈ €5–8/month. Measure the real
  idle draw; the EDID fix is what holds it at the low end.
- **Conditions to carry into setup (03):** apply the headless-idle EDID/dummy-plug
  fix; cap the battery charge threshold for longevity (battery = mini-UPS, not a
  full-outage UPS); plan the USB‑C Ethernet dongle as permanent wiring.

### Facts later tickets depend on

- Compute home candidate = ThinkBook (8c/16t + 6 GB CUDA), NAS = J4025 2c/2t + 6 GB.
- **NAS is enough for the light stuff** (*arr suite, small website — I/O-bound).
  Laptop earns its keep on Immich ML, heavy/parallel containers, transcoding,
  growth. *Which box runs what = keystone 03.*
- 2nd M.2 slot likely free → laptop *can* host a local backup copy (ticket 05),
  pending a physical peek.
- 32 GB RAM, non-expandable without swapping both DIMMs → cap on how many heavy
  containers co-reside.
