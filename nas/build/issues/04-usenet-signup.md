# 04 — Sign up usenet: Eweka + NZBGeek

**What to build:** The usenet provider + indexer accounts the media pipeline
([11](11-arr-stack.md)) needs to be testable end-to-end. Eweka (~€7/mo, European
retention) + NZBGeek (~$20/yr). Both need a card — **this is your manual task**, and
nothing else in the plan is blocked on it, so do it whenever.

Store the credentials via **sops-nix** ([03](03-secrets-management.md)), not in a
note — SABnzbd and Prowlarr consume them from there.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Eweka account active; server/port/credentials recorded
- [ ] NZBGeek account active; API key recorded
- [ ] Both stored as sops-nix secrets, not plaintext

_Detail: [PLAN.md](../../PLAN.md) → Decisions taken._
