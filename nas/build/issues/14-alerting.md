# 14 — Dead-man alerting

**What to build:** Monitoring that actually fires. This was **absent from the
original plan** — ticket 05 asserted "failure fires a notification" and named no
mechanism.

**Why dead-man, not error-triggered.** An unattended box in a cupboard fails
*silently*. A restic job that has been erroring for four months looks exactly like
one that works — the UI is identical: nothing. Alerting on errors only catches
failures that are alive enough to report themselves. **Alert on the absence of
success.**

Every timer pings **healthchecks.io** on completion; a missed ping raises the alarm.
Immediate hard failures additionally push via **ntfy** so you find out the same day.

**Coverage:**

| Signal | Why |
|---|---|
| Nightly restic → USB | copy #2 stopped |
| Nightly restic → Drive | copy #3 stopped |
| Weekly prune | the one dangerous op |
| Monthly `restic check` + sample restore | silent repo corruption |
| **Workspace pool usage threshold** | the repo growing into the quota that runs Gmail |
| NAS btrfs scrub + SMART | bit rot / a dying disk |
| NFS mount health | the dependency every service shares |
| `home-server` reachability | the SPOF itself |

Tokens from sops-nix ([03](03-secrets-management.md)).

**Blocked by:** 06 (home-server host). Extends as later tickets add timers.

**Status:** ready-for-agent

- [ ] healthchecks.io checks created for every timer above, with sane grace periods
- [ ] ntfy configured for immediate failures; delivery tested on a real device
- [ ] **Verified by deliberately breaking something** — disable a timer, confirm the alarm actually arrives
- [ ] NAS-side signals (scrub, SMART) wired in — DSM notifications count if they reach you
- [ ] Workspace pool threshold alert live
- [ ] Tokens from sops-nix

_Gap identified in review; see [05](../../issues/05-backup-topology.md#amendment--second-pass-2026-07-26)._
