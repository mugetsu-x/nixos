# 04 — Sign up usenet: Eweka + NZBGeek

**What to build:** The usenet provider + indexer accounts the media pipeline
([11](11-arr-stack.md)) needs to be testable end-to-end. Eweka (~€7/mo, European
retention) + NZBGeek (~$20/yr). Both need a card — **this is your manual task**, and
nothing else in the plan is blocked on it, so do it whenever.

Store the credentials via **sops-nix** ([03](03-secrets-management.md)), not in a
note — SABnzbd and Prowlarr consume them from there.

**Blocked by:** None — can start immediately.

**Status:** accounts + secrets done 2026-10-05. Only the smoke test remains.

**Where the secrets live.** `secrets/home-server.yaml` — not `main-pc.yaml`, since
main-pc never uses them. Its `.sops.yaml` rule is **walter-only** for now: the
home-server host doesn't exist yet, and [06](06-home-server-host.md) adds its key
and runs `sops updatekeys`. Nothing declares these as `sops.secrets.*` yet — that
happens in [11](11-arr-stack.md), on the host that consumes them.

| Key | What |
|---|---|
| `eweka_username` | Eweka account username |
| `eweka_password` | Eweka account password |
| `nzbgeek_api_key` | NZBGeek → Profile → API key (Prowlarr needs only this) |

Fill in with `sops secrets/home-server.yaml` (replace the `REPLACE_ME` values).
Do it in the editor, never via chat or a shell command line.

Server details aren't secret; record them here from the Eweka welcome mail /
account page, and 11 puts them in plain Nix:

- Eweka server: `news.eweka.nl`  port: **563 (SSL)** — not 119, that's plaintext  max connections: **50**

- [x] `secrets/home-server.yaml` + `.sops.yaml` rule (walter-only until 06)
- [x] Eweka account active (15-month plan, bought 2026-10-05, runs to ~2028-01-05; 30-day money-back window); server/port/connections recorded above
- [x] NZBGeek account active (user `kido`, yearly, expires 2027-10-08). API host `https://api.nzbgeek.info/`. The "GeekKey" **is** the API key — and the site login until a password is set
- [x] All three values filled in via `sops`; `sops -d secrets/home-server.yaml` shows no `REPLACE_ME` — 2026-10-05
- [ ] Smoke test before Eweka's money-back window closes (~2026-11-04): throwaway SABnzbd on main-pc, one small NZB from NZBGeek, full line speed, no missing articles

_Detail: [PLAN.md](../../PLAN.md) → Decisions taken._
