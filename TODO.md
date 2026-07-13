# TODO

Planned work on this config. Newest context at the top of each item so we do not
have to rediscover it.

## 1. Keyboard shortcuts / keybinds

Deferred from the session on 2026-07-13. Two parts:

**A real bug to fix first.** The workspace binds in `home/dotfiles/hypr/hyprland.conf`
use CTRL, which Hyprland grabs globally *before* the focused app sees it:

```
bind = CTRL, U, workspace, 1          # Ctrl+U = "delete line" in every shell
bind = CTRL, I, workspace, 2
bind = CTRL, O, workspace, 3
bind = CTRL, J, movetoworkspace, 1
bind = CTRL, K, movetoworkspace, 2    # Ctrl+K = "kill to end of line"
bind = CTRL, L, movetoworkspace, 3    # Ctrl+L = "clear screen"
```

So in kitty/zsh, Ctrl+L does not clear, Ctrl+U does not delete the line, and
Ctrl+K does not kill to end of line. Move workspaces to the conventional
`SUPER+1..9` (switch) and `SUPER+SHIFT+1..9` (move), which collide with nothing.

**Binds that are missing entirely:** fullscreen (`SUPER+F`), float toggle
(`SUPER+V`), directional focus (`SUPER+h/j/k/l` — today there is only
`cyclenext`, so focus cannot be moved in a direction), and mouse window
management:

```
bindm = SUPER, mouse:272, movewindow      # super+drag to move
bindm = SUPER, mouse:273, resizewindow    # super+right-drag to resize
```

Already done: `SUPER+L` locks (hyprlock), media keys drive playerctl.

## 2. E-book library and download flow

Not started. Wants a library plus a way to get books into it. Open questions:
which reader (Calibre? Foliate?), whether a Kobo/Kindle is in the picture, and
where the library lives on disk.

## 3. Manga downloader

Not started. Candidates to evaluate in nixpkgs.

## 4. Monitors and Hyprland behaviour

Not started. Today `hyprland.conf` is single-monitor and auto-detected:

```
monitor=,preferred,auto,auto
```

Needs the real monitor layout (how many, resolutions, refresh rates, physical
arrangement) plus whatever behaviour changes go with it — workspace-to-monitor
pinning, gaps/animations, focus behaviour. Note `input { follow_mouse = 0 }` is
click-to-focus today; confirm that is deliberate.

## 5. Development setup for the people-management-app

Not started. Need the stack before planning. Likely relevant to what is already
here: Neovim is LazyVim with Mason disabled, and the TypeScript/web toolchain
(nodejs_22, typescript, vtsls, eslint, prettierd) is in
`home/modules/neovim-lazyvim.nix`. Docker is enabled system-wide.

`direnv` + `nix-direnv` are now set up, so the intended shape is a per-project
`flake.nix` plus an `.envrc` containing `use flake` — project deps stay out of
the global profile. Adding a language server means adding the package to
`programs.neovim.extraPackages` *and* a `mason = false` entry (see CLAUDE.md).
