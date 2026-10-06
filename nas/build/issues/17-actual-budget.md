# 17 — Actual Budget (household budgeting)

**What to build:** [Actual Budget](https://actualbudget.org)'s sync server on
`home-server`. Envelope budgeting for the household, used from browsers and phones,
with the server keeping all devices in sync.

Added 2026-10-06 as a wish (Walter); **not grilled yet**.

**Shape (proposal):**
- nixpkgs has `services.actual`. The data is small (SQLite budget files), so it
  lives under `/var/lib` on NVMe.
- Reached over the LAN and the tailnet only, like everything else. Financial
  data never gets a public port.

**Things that will bite:**
- **Actual's web client needs HTTPS** (a browser *secure context*) on any
  address other than `localhost`. Plain `http://home-server:5006` loads but
  refuses to work. That's the first service in this plan that needs TLS. The
  likely answer is `tailscale serve` (a real cert on the `*.ts.net` name, nothing
  exposed publicly) or a reverse proxy with Tailscale certs. Settle it **once for
  every service** rather than per ticket. 18 (Home Assistant's mobile app) and
  the phones will want the same.
- **Automatic bank sync is the open risk.** For EU banks Actual relies on a
  third-party aggregator (historically GoCardless Bank Account Data, which has
  restricted new sign-ups). Check what currently works for Austrian banks
  before counting on it. CSV/OFX import always works.
- Budget files can be end-to-end encrypted with a password. If that password is
  lost, the data is gone. It goes into the password manager next to the restic one.

**Open questions:**
- One shared household budget, or separate budgets per person?
- Is bank sync a must-have, or is manual/CSV import acceptable?
- Is there history to import (spreadsheets such as the `Konto-Übersicht.xlsx` in
  Anja's folder, or another app's export)?

**Backup:** `/var/lib/actual` belongs in [13](13-restic-321-service.md). Small,
but irreplaceable. **Don't start real budgeting before 13 is green.**

**Blocked by:** 06, 07 (tailnet, for the HTTPS answer), 13 for real use.

**Status:** idea, not grilled
