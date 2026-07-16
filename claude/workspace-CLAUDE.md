# workspace

Home for all software projects. Every project is its own git repo in a
subdirectory here (`~/workspace/<project>/`). This file holds the house rules
that apply to **all** of them — Claude Code walks up the directory tree for
`CLAUDE.md`, so anything here is inherited by every project below.

The machine itself (toolchain, editor, drivers) is configured in
`~/nixos-config`. Read `~/nixos-config/CLAUDE.md` for how Node/pnpm/tsc/psql get
onto PATH, how Zed's language servers are wired, and the full scaffold recipe.
This file assumes that and only covers project-level conventions.

## Rules

- When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.

## Stack

TypeScript, fullstack. pnpm as the package manager. Postgres per project (runs
in Docker, not on the host). Zed is the primary editor; Neovim is `$EDITOR`.

## Scaffolding a new project

Order matters — `create-next-app` refuses a non-empty dir, so scaffold the app
_first_, then layer the Nix template on top (see `~/nixos-config/CLAUDE.md` →
"Starting a project" for the why):

```
mkdir ~/workspace/foo && cd ~/workspace/foo
pnpm create next-app .                    # global pnpm — no devShell yet
nix flake init -t ~/nixos-config#nextjs   # flake.nix, .envrc, compose.yaml, .env.example
echo ".direnv/" >> .gitignore
direnv allow                              # once; afterwards `cd` is enough
cp .env.example .env && docker compose up -d   # Postgres 16 on :5432
git init && git add -A && git commit -m "init"
```

After the repo exists, run `/setup-matt-pocock-skills` once to wire up the
engineering skills for it (issue tracker, triage labels, domain doc layout).
This is required before the triage/to-tickets/wayfinder/implement flows work.

Not every project is Next.js. For anything else, still give it a flake devShell

- `.envrc` so the per-project toolchain is pinned and direnv loads it — a bare
  global toolchain is only the fallback, never the intended per-project setup.

## Per-project conventions

- **Every project gets its own `CLAUDE.md`** at its root, describing what that
  project is, how to run it, and its non-obvious bits — the same style as
  `~/nixos-config/CLAUDE.md`. Keep it current as things land.
- **Track planned work in a `TODO.md`** at the project root; read it before
  starting something new.
- **Pin the toolchain per project** via a flake devShell loaded by direnv. The
  global `node`/`pnpm`/`tsc` from nixos-config is a fallback, not the norm.
- **Never commit** `.env`, `.direnv/`, `node_modules/`, or build output. `.env`
  is derived from `.env.example`, which _is_ committed.
- **`docker compose down -v` wipes the database.** The volume is project-scoped,
  so resetting is free.

## Skills

- `grill-me` — relentless interview to stress-test a plan or design before
  building. Say "grill me" (or invoke `/grill-me`) once a plan exists and you
  want every branch of the decision tree resolved before writing code. It is a
  user-level skill (`~/.claude/skills/grill-me/`), so it's available in every
  project here.
- **Matt Pocock's engineering skills** — installed user-level in
  `~/.claude/skills/` (so available in every project): `ask-matt` (router over
  the rest), `tdd`, `code-review`, `diagnosing-bugs`, `research`, `prototype`,
  `codebase-design`, `domain-modeling`, `resolving-merge-conflicts`,
  `grill-with-docs`, `implement`, `to-spec`, `to-tickets`, `triage`,
  `wayfinder`, `improve-codebase-architecture`, `setup-matt-pocock-skills`.
  **Every new project must run `/setup-matt-pocock-skills` once** before the
  tracker-backed flows (triage/to-tickets/wayfinder/implement) work. `/ask-matt`
  routes you to the right skill for a given situation. `/code-review` here is
  Matt's two-axis (Standards + Spec) review, which shadows the built-in one.
