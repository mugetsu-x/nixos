{ pkgs, ... }: {
  programs.steam = {
    enable = true;

    # Steam's module turns on hardware.graphics.enable32Bit for us, which is what
    # gets the 32-bit NVIDIA driver in place for older titles.

    # Ship GE-Proton alongside Valve's Proton. It shows up in Steam under
    # Compatibility as "GE-Proton…" and fixes a lot of titles that stock Proton
    # trips over. Updating it is a nixpkgs bump, not a protonup download.
    extraCompatPackages = [ pkgs.proton-ge-bin ];

    # Steam Input, Wine prefix poking, and non-Steam game shims.
    protontricks.enable = true;

    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Lets games ask the kernel for the performance governor and higher scheduling
  # priority for as long as they are running. Steam launch option:
  #   gamemoderun %command%
  programs.gamemode.enable = true;

  # Micro-compositor to run a game in. Gives a game its own Wayland session, so
  # resolution changes and alt-tab stop disturbing the rest of Hyprland.
  # Steam launch option:
  #   gamescope -W 2560 -H 1440 -r 144 -f -- %command%
  programs.gamescope.enable = true;
}
