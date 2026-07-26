# ThinkPad "16p Gen 2" as an always-on home server

> ⚠️ **CORRECTION (2026-07-26, from ticket 01 — specs read off the unit).**
> This note guessed the wrong machine. The actual hardware is a **Lenovo
> ThinkBook 16p Gen 2 (type 20YM)** — a consumer creator/gaming laptop — with an
> **AMD Ryzen 9 5900HX** and a **consumer GeForce RTX 3060 Laptop 6 GB**, *not*
> the Intel-HX + professional-RTX-Ada "P16 Gen 2" assumed below. Consequences:
> **no AV1 encode** (Ada-only; the 3060 does H.264/HEVC encode + AV1 decode),
> the **GeForce NVENC session cap applies** (3, raised to 8 by driver; patchable),
> and VRAM is **6 GB**, not 8–16 GB. The Immich-ML value case still holds (6 GB
> CUDA Ampere runs Immich's models fine); the AV1/pro-card/unlimited-sessions
> case does **not**. The always-on caveats below (idle power, headless-idle EDID
> penalty, no built-in Ethernet, battery-as-UPS) all still apply. See ticket 01
> for the verified spec sheet and always-on verdict.

Research note, written 2026-07-24. Feeds the decision: should the spare Lenovo
laptop become the 24/7 home server alongside the Synology **DS420+**
("Alexandria"), and should the media / *arr / Immich workload relocate to it
from the weak NAS Celeron?

**Bottom line up front:** the hardware is a large overkill for this job and its
NVIDIA dGPU is a genuinely excellent transcode/ML engine that leaves the NAS's
Celeron in the dust. The two real caveats are (a) **idle power** — it is a
200 W+ workstation chassis, not a 10 W NAS, and the NVIDIA dGPU has a
well-documented *headless idle penalty* — and (b) **no built-in wired Ethernet**.
NixOS support is good and adding it as a second flake host is straightforward.

---

## 0. Model confirmation

There is no Lenovo product literally called "ThinkPad 16p Gen 2." The marketing
name is almost certainly the **Lenovo ThinkPad P16 Gen 2 (16″ Intel)** — the
big-chassis mobile workstation (Lenovo's "P16", "16″", "power-packed mobile
workstation"). "16p" is a transposition of "P16". Model type numbers are
`21FA...` (e.g. `21FA0028US`, `21FA002AUS`).

**Do not confuse it with the adjacent, weaker models** — the naming is a minefield:

| Model | What it is | Discrete GPU ceiling |
|---|---|---|
| **P16 Gen 2** ← *almost certainly this one* | Full workstation, Intel **HX** desktop-class CPU | up to RTX **5000** Ada 16 GB |
| P16v Gen 2 (Intel) | Thinner "v" workstation | lower Ada / RTX 3000-class |
| P16s Gen 2 (Intel/AMD) | Thin-and-light, **U-series** CPU | RTX 500/1000/2000 Ada or iGPU |

The specs below are for the **P16 Gen 2** (the HX one). **Confirm the user's
actual unit** — the sticker/`21FA…` type number, and ideally
`sudo dmidecode -t system` / `lscpu` / `nvidia-smi` on the box — because CPU, RAM
and especially the GPU vary per SKU and every downstream conclusion depends on
which GPU is fitted.

Sources: [Lenovo P16 Gen 2 product page](https://www.lenovo.com/us/en/p/laptops/thinkpad/thinkpadp/thinkpad-p16-gen-2-16-inch-intel/21fa0028us),
[Lenovo PSREF – ThinkPad P16 Gen 2 (PDF)](https://psref.lenovo.com/syspool/Sys/PDF/ThinkPad/ThinkPad_P16_Gen_2/ThinkPad_P16_Gen_2_Spec.pdf),
[thinkstation-specs.com – P16 Gen 2](https://thinkstation-specs.com/thinkpad/p16-gen-2/).

---

## 1. Spec range (P16 Gen 2, Intel HX)

Per Lenovo PSREF and the thinkstation-specs.com PSREF mirror:

- **CPU** — 13th-gen (Raptor Lake) or 14th-gen Intel Core **HX**-series, vPro
  optional. Options seen: i5-13600HX, i7-13700HX, i7-13850HX, i9-13950HX,
  i9-13980HX, and 14th-gen i7-14700HX. These are **desktop-class 55 W (base)
  HX** parts — up to 24 cores. Enormously more CPU than the DS420+'s 2-core
  Celeron J4025; even a pure-CPU (software) transcode path would dwarf the NAS.
- **RAM** — **DDR5 SO-DIMM, 4 DIMM sockets**. Max **192 GB non-ECC** (or
  **128 GB ECC**). The chassis takes ECC SO-DIMMs — nice for an always-on box,
  though not required for this workload.
- **NVIDIA discrete GPU** (the SKU that matters — verify the actual unit):
  | GPU | VRAM | Notes |
  |---|---|---|
  | RTX A1000 | 6 GB | Ampere (older gen) |
  | RTX 1000 Ada | 6 GB | Ada |
  | RTX 2000 Ada | 8 GB | Ada, AD107 |
  | RTX 3500 Ada | 12 GB | Ada |
  | RTX 4000 Ada | 12 GB | Ada |
  | RTX 5000 Ada | 16 GB | Ada, top SKU |

  Most P16 Gen 2 units ship an **Ada-generation** RTX (2000/3500/4000/5000).
  Only the base **RTX A1000** is the older **Ampere** generation — this
  distinction matters for AV1 encode (see §3).
- **Storage** — **2× M.2 2280 PCIe NVMe** slots, up to **4 TB each** (8 TB
  total). So there is typically a free second slot for a data/cache disk
  (SSD-only; no room for 3.5″ media disks — bulk media stays on the NAS).
- **Wired NIC** — **none built in.** The P16 Gen 2 has **no RJ-45 port**;
  wired Ethernet is only via a USB-C/Thunderbolt dongle or dock. On-board
  networking is **Wi-Fi** (Lenovo module code "WM790", Wi-Fi 7 class) +
  Bluetooth. **This is a real gap for an always-on server** — plan on a
  USB-C / Thunderbolt **2.5GbE (or faster) adapter** or a dock for a stable
  wired link. (The DS420+ itself has 2× 1GbE with link aggregation.)
- **Battery** — integrated **~94 Wh** Li-Polymer (some listings say 90 Wh;
  PSREF for this review unit says 94 Wh).
- **AC adapter** — **slim-tip 170 W / 230 W** (top GPU SKUs may ship 300 W).
  The high wattage reflects peak CPU+GPU draw, **not** idle.

Sources: [thinkstation-specs.com – P16 Gen 2](https://thinkstation-specs.com/thinkpad/p16-gen-2/),
[Lenovo PSREF (PDF)](https://psref.lenovo.com/syspool/Sys/PDF/ThinkPad/ThinkPad_P16_Gen_2/ThinkPad_P16_Gen_2_Spec.pdf),
[StorageReview – P16 Gen 2 review](https://www.storagereview.com/review/lenovo-thinkpad-p16-gen-2)
(review unit: i7-14700HX / RTX 4000 Ada 115 W / 32 GB / 1 TB).

---

## 2. Always-on viability

### Power draw
Exact **whole-system idle watts for the P16 Gen 2 are not cleanly published** in
the sources reviewed (Notebookcheck's power table did not survive extraction),
so treat the following as an *informed range* and **measure the actual unit**
with a plug meter before committing:

- **Idle** — for an HX + RTX-Ada 16″ chassis, expect roughly **8–15 W** at the
  low end (display dimmed/off, CPU parked) up to **~25–35 W** for "on but idle"
  with the panel lit. As a headless server the panel is off (saves several W),
  but see the dGPU caveat below.
- **Light server load** (containers idle, occasional disk I/O): realistically
  **~15–35 W**.
- **Transcode / ML burst**: the dGPU adds tens of watts only while a job runs
  (a single NVENC transcode is a fraction of the GPU's TGP); NVENC is far more
  power-efficient than a CPU software transcode.
- **Full CPU+GPU load**: this is why the adapter is 170–230 W+ — the RTX Ada
  options run **up to 115–130 W TGP** and the HX CPU another 55–157 W. You will
  never see this on a media/*arr/Immich workload except during Immich ML
  batch jobs.

**The NVIDIA headless-idle penalty (important).** NVIDIA GPUs are documented to
*fail to reach their lowest idle power state when no display/EDID is present*.
On a desktop RTX 3090 the community measured **~25 W idle headless vs ~13 W with
a monitor/EDID attached**; the GPU sits in P8 but at an elevated draw. The same
mechanism applies to the Ada laptop dGPU (smaller absolute numbers). Mitigations:
a **dummy HDMI/EDID plug**, or a kernel **fake-EDID** (`drm.edid_firmware=…`,
`nvidia-drm.modeset=1`), or an hourly `suspend/resume` cron on
`/proc/driver/nvidia/suspend`. Net effect: to keep NVENC available you keep the
dGPU powered, and headless it will idle a few watts higher than it "should"
unless you feed it a fake EDID.
Source: [NVIDIA Developer Forums – high idle power headless](https://forums.developer.nvidia.com/t/high-idle-power-consumption-in-headless-server-without-monitor-connected/311064).

**Framing for the decision:** even a good-case **~15–25 W** idle is *far* above a
DS420+ NAS (single-digit to ~15 W idle). This laptop is not a low-idle appliance;
it is a workstation you would be running 24/7. Whether that is acceptable is a
running-cost question (≈ 20 W × 24 h × 365 ≈ **175 kWh/yr**, ballpark, plus the
NAS still running for storage).

### Thermals & fan noise at idle
Reviews describe the cooling as large and comparatively quiet **for a
workstation**: under combined CPU+GPU load fan noise is "a soft to moderate
whisper" thanks to big intakes/outlets and heavy copper heatsinks, though it
"can get loud… under heavy load or plugged in." At idle / light server load the
fans should be near-silent or off. For a media server the sustained thermal load
is trivial relative to the chassis's design point.
Sources: [StorageReview](https://www.storagereview.com/review/lenovo-thinkpad-p16-gen-2),
[Notebookcheck P16 Gen 2 review](https://www.notebookcheck.net/Lenovo-ThinkPad-P16-Gen-2-workstation-review-Heavy-with-supercharged-graphics.903804.0.html).

### Headless / lid-closed reliability
- ThinkPads run fine headless and lid-closed; on Linux set the logind lid
  switch to ignore (`services.logind.lidSwitch = "ignore"` /
  `lidSwitchExternalPower = "ignore"` on NixOS). No display needed except for
  the dGPU EDID caveat above.
- **Battery as a de-facto UPS.** The integrated ~94 Wh battery *does* give you a
  built-in UPS — the machine rides through mains blips and short outages and can
  shut down cleanly. Two caveats for 24/7 use: (1) keeping a Li-Po battery
  permanently at 100 % ages it; Lenovo firmware/Linux (`tlp`, or Lenovo's
  charge-threshold sysfs) can **cap charge at ~60–80 %** to preserve longevity —
  worth enabling. (2) It is a genuine but *modest* UPS: ~94 Wh at ~20 W idle is
  a few hours, but far less under load. It protects against blips and gives
  clean-shutdown headroom; it is not a substitute for a real UPS if uptime
  through long outages matters (and the NAS it serves has no such battery).

---

## 3. NVIDIA transcoding vs the NAS Celeron

### The laptop's Ada dGPU (NVENC/NVDEC)
Ada-generation RTX (2000/3500/4000/5000 Ada) carry NVIDIA's **8th-generation
NVENC encoder with AV1 encode**, plus NVDEC decode for **H.264/AVC, HEVC/H.265,
VP9, and AV1**. 8th-gen NVENC AV1 is ~40 % more efficient than its H.264 and is
a current-generation, high-quality transcode engine.

Two points that matter for a media/photo server:
- **AV1 encode requires an Ada card.** The RTX **2000/3500/4000/5000 Ada** have
  it. The base **RTX A1000 is Ampere** and has 7th-gen NVENC — **no AV1
  encode** (still fine for H.264/HEVC). So confirm the unit's GPU if AV1 output
  matters.
- **Concurrent-session limit — this is the big win over a consumer card.**
  Consumer GeForce cards historically capped at 3 simultaneous NVENC sessions
  (recently raised to 8). **NVIDIA workstation/professional cards — which is
  exactly what the RTX Ada in this laptop is — have *no* artificial session cap**
  (limited only by hardware/VRAM). For a Jellyfin server that could serve many
  streams at once, an unrestricted professional NVENC is materially better than
  a GeForce.

Sources: [NVIDIA RTX Ada laptop GPUs (8th-gen NVENC, AV1)](https://blogs.nvidia.com/blog/rtx-ada-ai-workflows/),
[Notebookcheck – RTX 2000 Ada Laptop specs](https://www.notebookcheck.net/NVIDIA-RTX-2000-Ada-Generation-Laptop-GPU-Benchmarks-and-Specs.744893.0.html),
[Tom's Hardware – NVENC session limits](https://www.tomshardware.com/news/nvidia-increases-concurrent-nvenc-sessions-on-consumer-gpus),
[VideoCardz – GeForce 8 concurrent sessions; workstation unlimited](https://videocardz.com/newz/nvdia-geforce-gpus-now-support-up-to-8-concurrent-nvenc-encoding-sessions).

Beyond transcode: the dGPU also has **CUDA + Tensor cores + 8–16 GB VRAM**,
which is exactly what **Immich machine learning** (face/object recognition, CLIP
search) wants. This is a capability the NAS simply does not have.

### The NAS's Intel Celeron J4025 (UHD Graphics 600 QuickSync)
The J4025 is **Gemini Lake Refresh** (Gen 9.5 graphics, UHD 600). Its QuickSync
does **H.264 decode+encode, HEVC/H.265 8-bit & 10-bit decode+encode, VP9 decode,
VP8**. It has **no AV1** support (AV1 decode arrived with Tiger Lake; AV1 encode
with Arc/Meteor Lake — both far newer). It is a genuinely capable *light*
QuickSync engine for a handful of H.264/HEVC streams, but it is a 2-core, 2 GB
appliance whose real ceiling is CPU/RAM, not the fixed-function transcoder.
Source: [Intel media capabilities / UHD 600 codec support](https://www.intel.com/content/www/us/en/docs/onevpl/developer-reference-media-intel-hardware/1-1/overview.html)
(and cpu-monkey UHD 600). NB: some third-party spec pages over-claim UHD 600 AV1
support — Gemini Lake predates AV1 in QuickSync; treat AV1 as **not** available
on the NAS.

### Verdict (transcode/ML)
The laptop's Ada dGPU is **categorically superior**: current-gen 8th-gen NVENC
with **AV1 encode**, **unlimited concurrent sessions** (professional card), and
**CUDA/VRAM for Immich ML** — none of which the Celeron has. *However*, per the
NAS plan the home playback path is an **NVIDIA Shield that direct-plays almost
everything, so transcoding rarely fires at all.** So the transcode advantage is
real but only *occasionally* exercised for media; the **Immich ML** advantage
(and headroom for future many-stream/remote scenarios) is the more concrete,
everyday win.

---

## 4. NixOS support

### Hardware support
- **CPU / platform**: Intel HX (Raptor Lake) is fully supported on NixOS
  `nixos-25.05` — nothing special.
- **NVIDIA dGPU headless**: well-trodden. Use `hardware.nvidia`, unfree driver
  allowed (this repo already sets `allowUnfree` in `modules/common.nix`). The
  **open kernel module** (`hardware.nvidia.open = true`) supports Turing and
  newer, so **all the Ada SKUs qualify** (the base A1000 is Ampere — also fine;
  open module supports Turing+). This repo already runs the NVIDIA open driver
  in `modules/nvidia.nix`, so the pattern is in hand.
- **Headless graphics stack**: set **`hardware.graphics.enable = true`** so
  `/run/opengl-driver` exists — required for GPU compute/transcode even with no
  desktop. Enable `hardware.nvidia.nvidiaPersistenced = true` (persistence mode)
  for a headless server.
- **Container GPU passthrough**: `hardware.nvidia-container-toolkit.enable = true`
  for Docker/Podman (Jellyfin/Immich containers), then request the GPU in
  compose. Jellyfin needs the NVENC/NVDEC libs; NixOS wiki documents the
  `jellyfin` native path too.

### Known gotchas
- **Headless idle power / P-state** (see §2) — feed a fake EDID
  (`drm.edid_firmware`, `nvidia-drm.modeset=1`) or accept a few extra idle watts.
- **No RJ-45** — you must configure networking over a **USB/Thunderbolt Ethernet
  adapter** (or Wi-Fi). Plan the dongle before relying on it.
- **Lid switch** — set `services.logind.lidSwitch = "ignore"` (and the
  external-power variant) so closing the lid doesn't suspend the server.
- **Suspend/resume** is irrelevant for an always-on box but NVIDIA
  suspend-on-laptop quirks are a common complaint — avoid by simply not
  suspending.
- **Battery longevity** — cap charge threshold via `tlp` /
  `services.thinkfan`-adjacent sysfs, since it will sit on mains 24/7.

### Second flake host — feasibility
**Straightforward.** This repo is already a flake with a single
`nixosConfigurations.main-pc`. Adding the laptop is additive:

- Add `nixosConfigurations.<newhost>` in `flake.nix` (e.g. a `home-server` /
  the box's hostname) pointing at a new `hosts/<newhost>.nix`.
- Reuse `modules/common.nix`, `modules/nvidia.nix` (or a headless variant), and
  add a server-flavoured module set: **no** Hyprland/greetd/desktop, **yes**
  `hardware.graphics.enable`, `nvidia-container-toolkit`, Docker/Podman,
  `services.logind` lid settings, sshd, and the media/*arr/Immich stack.
- Generate `hosts/<newhost>/hardware-configuration.nix` on the actual box
  (`nixos-generate-config`) — disk UUIDs and kernel modules are machine-specific
  (this repo keeps that in `modules/hardware.nix` for main-pc).
- CI (`nix flake check --no-build`) will simply evaluate both hosts.

Nothing about a second host is unusual; the existing NVIDIA-on-NixOS knowledge in
this repo transfers directly. The **only new work** is a headless-server module
set and the hardware-configuration for the new machine.

Sources: [NixOS Wiki – Jellyfin (NVIDIA)](https://wiki.nixos.org/wiki/Jellyfin),
[Jellyfin docs – NVIDIA hardware acceleration](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/nvidia/),
[NixOS Discourse – jellyfin-ffmpeg NVIDIA transcode](https://discourse.nixos.org/t/jellyfin-ffmpeg-fails-to-transcode-using-nvidia-gpu/75064).

---

## 5. Executive summary

- **Model** = **Lenovo ThinkPad P16 Gen 2 (16″ Intel)**, the HX-class mobile
  workstation (type `21FA…`). "16p Gen 2" is a transposition of "P16 Gen 2".
  *Confirm the exact unit's CPU/RAM/GPU on the box.*
- **Specs**: Intel 13th/14th-gen **HX** CPU (up to 24 cores), **DDR5** to
  **192 GB** across 4 SO-DIMM slots, an **NVIDIA RTX Ada** dGPU
  (2000/3500/4000/5000 Ada, 8–16 GB — or base RTX A1000 6 GB Ampere), **2× M.2
  NVMe** (one likely free), **~94 Wh** battery, 170–230 W adapter.
- **Transcode/ML verdict**: the Ada dGPU is **far** ahead of the NAS Celeron —
  **8th-gen NVENC with AV1 encode**, **unlimited concurrent sessions** (it's a
  *professional* card, not GeForce), and **CUDA/VRAM for Immich ML**. The
  J4025's UHD 600 QuickSync does H.264/HEVC only, **no AV1**, on 2 cores / 2 GB.
- **But transcoding rarely fires**: home playback is via a direct-playing
  NVIDIA Shield, so the everyday win is **Immich ML** and headroom, not routine
  media transcode.
- **Power verdict**: this is a **200 W+ workstation chassis**, not a low-idle
  appliance. Realistic idle **~15–25 W** (measure it), well above a DS420+.
  Watch the **NVIDIA headless-idle penalty** (dGPU won't reach lowest idle
  without a display/EDID) — mitigate with a dummy/fake EDID.
- **Networking gap**: **no built-in RJ-45** — needs a USB-C/Thunderbolt Ethernet
  adapter (or Wi-Fi) for a stable wired link.
- **Battery-as-UPS**: yes, the ~94 Wh internal battery is a genuine mini-UPS
  (blips + clean shutdown), but cap the charge threshold for longevity and don't
  treat it as a full outage UPS.
- **NixOS verdict**: **well supported and low-risk.** Adding it as a second
  `nixosConfigurations.<host>` is straightforward and additive; reuse the repo's
  existing NVIDIA-open-driver setup, add `hardware.graphics.enable`,
  `nvidia-container-toolkit`, lid-ignore, and a headless (no-desktop) module set.
  Main gotchas are the headless-idle EDID quirk and the Ethernet dongle.

**Config-dependent, confirm on the unit:** exact CPU model, RAM amount/ECC,
**which GPU (drives the AV1/session/ML verdict)**, and measured wall-power idle.
