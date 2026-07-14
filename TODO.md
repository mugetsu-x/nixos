# TODO

Planned work on this config. Newest context at the top of each item so we do not
have to rediscover it.

## 1. E-book library and download flow

Not started. Wants a library plus a way to get books into it. Open questions:
which reader (Calibre? Foliate?), whether a Kobo/Kindle is in the picture, and
where the library lives on disk.

## 2. Manga downloader

Not started. Candidates to evaluate in nixpkgs.

## 3. Monitors and Hyprland behaviour

Not started. Today `hyprland.conf` is single-monitor and auto-detected:

```
monitor=,preferred,auto,auto
```

Needs the real monitor layout (how many, resolutions, refresh rates, physical
arrangement) plus whatever behaviour changes go with it — workspace-to-monitor
pinning, gaps/animations, focus behaviour. Note `input { follow_mouse = 0 }` is
click-to-focus today; confirm that is deliberate.

## 4. Development setup for the people-management-app

Not started. Need the stack before planning. Likely relevant to what is already
here: Neovim is LazyVim with Mason disabled, and the TypeScript/web toolchain
(nodejs_22, typescript, vtsls, eslint, prettierd) is in
`home/modules/neovim-lazyvim.nix`. Docker is enabled system-wide.

`direnv` + `nix-direnv` are now set up, so the intended shape is a per-project
`flake.nix` plus an `.envrc` containing `use flake` — project deps stay out of
the global profile. Adding a language server means adding the package to
`programs.neovim.extraPackages` *and* a `mason = false` entry (see CLAUDE.md).
