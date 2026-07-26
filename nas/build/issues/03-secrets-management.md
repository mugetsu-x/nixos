# 03 — Secrets management (sops-nix)

**What to build:** Encrypted, in-repo secrets for both hosts via **sops-nix**, keyed
to each host's SSH host key plus a personal age key.

**Why this gates everything.** This repo has a **public GitHub remote** and CI runs
`nix flake check` on every push. Every service in the plan needs a credential:

| Secret | Needed by |
|---|---|
| restic repo password | [13](13-restic-321-service.md) |
| rclone / Google Drive OAuth token | [02](02-seed-google-drive-offsite.md), [13](13-restic-321-service.md) |
| Tailscale auth key | [07](07-tailscale-overlay.md) |
| Eweka credentials | [11](11-arr-stack.md) |
| NZBGeek API key | [11](11-arr-stack.md) |
| Immich DB password | [09](09-deploy-immich.md) |
| healthchecks.io / ntfy tokens | [14](14-alerting.md) |

Retrofitting secrets after the fact means rotating every one of them, so it goes
first. This was **not in the original plan at all** — the old tickets said
"credentials recorded" with no mechanism.

**Blocked by:** None — can start immediately, in parallel with 01/02.

**Status:** ready-for-agent

- [ ] `sops-nix` added as a flake input; `.sops.yaml` defines the key set
- [ ] age key for the user; host keys for `main-pc` and `home-server` enrolled
- [ ] At least one secret round-trips: encrypted in git, decrypted at activation, readable only by its service user
- [ ] `nix flake check --no-build` still passes in CI with encrypted files present
- [ ] Key backup stored **off** both machines (password manager + printed)
- [ ] Documented in `CLAUDE.md` so future work doesn't hand-roll a second mechanism

_Decision detail: [03](../../issues/03-keystone-server-or-not.md#amendment--second-pass-2026-07-26)._
