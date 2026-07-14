# nixos-config

Flake-based NixOS config for a single machine. One host (`main-pc`), one user
(`rennsemml`). Hyprland on Wayland, NVIDIA, Catppuccin Macchiato Blue everywhere.

Remote: `git@github.com:mugetsu-x/nixos.git`. CI runs `nix flake check --no-build`
on every push (`.github/workflows/check.yml`).

Planned work lives in [TODO.md](TODO.md) — read it before starting something new,
and keep it updated as items land.

## Rebuild

```
nixre     # alias for: sudo nixos-rebuild switch --flake ~/nixos-config#main-pc
nixhome   # alias for: cd ~/nixos-config
```

Both aliases are defined in `home/modules/shell.nix`, not in a shell rc file.

Channel: nixpkgs `nixos-25.05`, home-manager `release-25.05` (pinned to follow
nixpkgs). `system.stateVersion` and `home.stateVersion` are both `25.05` — do not
bump these to "update"; they are compatibility markers.

## Layout

```
flake.nix              inputs + the single nixosConfigurations.main-pc
hosts/main-pc.nix      host entrypoint: imports modules/, wires home-manager
modules/               system-level (NixOS options)
  hardware.nix         disk UUIDs, kernel modules — machine-specific, rarely touched
  nvidia.nix           nvidia open driver + Wayland env vars
  common.nix           bootloader, networking, locale, audio, bluetooth, fonts, user
  login.nix            greetd + regreet greeter, UWSM-managed Hyprland session
  gaming.nix           steam (+ GE-Proton), gamemode, gamescope
home/
  rennsemml.nix        home-manager entrypoint: imports home/modules/
  modules/             user-level (home-manager options)
    packages.nix       home.packages — the big app/CLI list
    shell.nix          zsh (aliases live here) + starship prompt
    wayland.nix        links dotfiles/ into ~/.config; waybar/hyprpaper/mako,
                       hyprlock, hypridle
    services.nix       cliphist, udiskie, blueman-applet + the hand-written
                       bt-autoconnect unit
    neovim-lazyvim.nix LazyVim starter pinned by commit + LSP/formatter overrides
    chrome.nix         google-chrome + Wayland .desktop override + default browser
    theme.nix          GTK/Qt theming, cursor, qt6ct palette
    pwas.nix           Chrome --app= desktop entries (Teams, Outlook, Notion, ...)
    gaming.nix         mangohud, vulkan-tools (system half is modules/gaming.nix)
  dotfiles/            raw config files, sourced verbatim by wayland.nix
    hypr/ kitty/ mako/ waybar/ wofi/
```

## Where things go

- **New CLI tool or GUI app** → `home/modules/packages.nix`.
- **System service, driver, hardware, boot** → `modules/`.
- **Anything scoped to my user** → `home/modules/`.
- **Hyprland/waybar/kitty/wofi/mako tweaks** → edit the file in `home/dotfiles/`
  directly. These are plain config files symlinked in by `wayland.nix`; you do
  not need to touch Nix to change a keybind or a bar module.
- **Something that should run in the background** → prefer a home-manager module
  (`services.foo.enable`) over `exec-once` in `hyprland.conf` or a hand-written
  `systemd.user.services` block. See below.
- **Shell alias** → `shellAliases` in `home/modules/shell.nix`.

## Conventions that matter

- **home-manager runs as a NixOS module**, not standalone. `useGlobalPkgs` and
  `useUserPackages` are both `true`, so user packages land in
  `/etc/profiles/per-user/rennsemml/bin`, **not** `~/.nix-profile/bin`. If
  something references `~/.nix-profile`, it is stale.
- `backupFileExtension = "hm-bak"` — home-manager will move conflicting files to
  `*.hm-bak` instead of failing the switch.
- `allowUnfree = true` is set once in `modules/common.nix` and inherited by
  home-manager via `useGlobalPkgs`. Don't re-declare it in `home/`.
- Nix files are formatted with **nixfmt-rfc-style** (the `nixfmt` binary).
- Neovim is LazyVim, **Mason is disabled** — every LSP and formatter is installed
  through `programs.neovim.extraPackages` and marked `mason = false`. Adding a
  language server means adding the package there *and* the `mason = false` entry.
- The LazyVim starter is pinned by `rev` + `sha256`. Bumping it requires updating
  both.
- Theming is Catppuccin **Macchiato, Blue accent**, dark. Palette hexes are
  duplicated in `theme.nix` (Qt colors), `shell.nix` (starship), and the waybar/
  kitty/wofi dotfiles — a color change touches several files.
- `nix.gc` runs weekly, deleting generations older than 14 days; boot menu is
  capped at 20 entries.
- **Background apps are systemd user units, not `exec-once`.** waybar, hyprpaper,
  cliphist, udiskie and blueman-applet are enabled via their home-manager
  modules; mako is D-Bus activated. The *only* remaining `exec-once` in
  `hyprland.conf` is the polkit agent. Debug them with
  `journalctl --user -u waybar` etc., not by hunting for stray processes.
- These modules generate a config file *only* when their `settings` option is
  non-empty. We deliberately leave `settings` unset so the raw files in
  `home/dotfiles/` remain the source of truth. If you ever set `settings`, it
  will collide with the `xdg.configFile` link in `wayland.nix`.

## Non-obvious bits

- Chrome and all PWAs are launched with `--ozone-platform-hint=wayland`. The
  Gemini PWA additionally uses a separate `--user-data-dir` so it has its own
  Google login, isolated from the main Chrome profile.
- `nix-claude-code` is a third-party flake input, installed as a *system* package
  in `hosts/main-pc.nix` and passed through `specialArgs`. It is pinned with
  `inputs.nixpkgs.follows = "nixpkgs"` — without that it drags in a second, full
  nixos-unstable nixpkgs. Keep the `follows`.
- The bluetooth auto-connect user service is a shell script built inline with
  `pkgs.writeShellScript` in `home/modules/services.nix`.
- **Hyprland keybind keys are XKB keysym names, and a bad one fails silently.**
  Hyprland registers the bind and shows it in `hyprctl binds`, but it can never
  fire — `ESC` is not a keysym (`Escape`/`escape` is), so `bind = SUPER, ESC`
  looks correct and does nothing. If a bind is listed but dead, check the keysym
  name first.
