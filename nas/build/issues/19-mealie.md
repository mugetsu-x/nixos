# 19 — Mealie (recipes + meal planning)

**What to build:** [Mealie](https://mealie.io) on `home-server`, the household
recipe collection. Import recipes from any URL, plan meals, generate shopping
lists, shared between Walter and Anja.

Added 2026-10-06 as a wish (Walter); **not grilled yet**.

**Shape (proposal):**
- nixpkgs has `services.mealie`. Data is small (SQLite or Postgres plus recipe
  images), so it lives under `/var/lib` on NVMe.
- One household, two users. Mealie has groups/households built in.

**Things that will bite:**
- **There's an existing collection to bring in:** `Anja/07_Rezepte` in the evac
  copies (not imported into Immich, deliberately). Check what format it's in
  (PDFs, photos, Word files, links) before promising an import. Mealie scrapes
  URLs well, but scanned or photographed recipes need manual entry or OCR.
- Optional AI features (parsing ingredients, importing from images) need an
  OpenAI-compatible API key. Off unless wanted, and via sops if turned on.
- Set the `BASE_URL` to the name it's actually reached by, so shared links and
  emails point at the right place.

**Open questions:**
- What's in `Anja/07_Rezepte`, and how much of it should become Mealie recipes?
- Is the shopping list used on phones in the shop? Then it needs reliable phone
  access (tailnet) and maybe the HTTPS answer from [17](17-actual-budget.md).
- Is meal planning wanted, or just a recipe box?

**Backup:** `/var/lib/mealie` goes into [13](13-restic-321-service.md).

**Blocked by:** 06, 13 for real use.

**Status:** idea, not grilled
