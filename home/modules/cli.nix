{ pkgs, ... }: {
  # Ctrl+R fuzzy history search, Ctrl+T fuzzy file picker, Alt+C fuzzy cd.
  programs.fzf.enable = true;

  # Frecency-ranked jumps: `z nixos` lands in ~/nixos-config from anywhere,
  # `zi` picks interactively. Plain `cd` is untouched.
  programs.zoxide.enable = true;

  # cat with syntax highlighting and git gutters.
  programs.bat.enable = true;

  # Modern ls. The zsh integration replaces ls/ll/la/lt with eza equivalents.
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };

  programs.btop.enable = true;
  programs.yazi.enable = true;

  # Per-project dev shells that activate on cd. nix-direnv adds caching, so a
  # shell.nix / flake.nix does not get re-evaluated on every directory change.
  # Usage: drop a .envrc containing `use flake`, then run `direnv allow`.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    du-dust # `dust` — disk usage, largest first
    playerctl # drives the media keys bound in hyprland.conf
  ];
}
