{ pkgs, ... }:
{
  # main-pc's half of the desktop config. wayland.nix links everything the
  # hosts share; the files here name main-pc's monitors, so they cannot be.
  xdg.configFile."hypr/host.conf".source = ../dotfiles/hosts/main-pc/hyprland.conf;
  xdg.configFile."hypr/hyprpaper.conf".source = ../dotfiles/hosts/main-pc/hyprpaper.conf;
  xdg.configFile."waybar/config.jsonc".source = ../dotfiles/hosts/main-pc/waybar.jsonc;

  # See wayland.nix for why these units restart when their files change.
  systemd.user.services.waybar.Unit.X-Restart-Triggers = [
    "${../dotfiles/hosts/main-pc/waybar.jsonc}"
  ];
  # Static wallpaper. hyprpaper.conf names the ultrawide explicitly; the 1080p
  # panel's background layer belongs to mpvpaper below.
  systemd.user.services.hyprpaper.Unit.X-Restart-Triggers = [
    "${../dotfiles/hosts/main-pc/hyprpaper.conf}"
  ];

  # Video wallpaper on the 1080p panel only, matched by its description rather
  # than DP-n (see the host's hyprland.conf). No home-manager module exists for
  # mpvpaper, so this is hand-written — but it is still a systemd user unit, not
  # an `exec-once`. mpvpaper is referenced by store path rather than added to
  # home.packages: nothing else needs it on PATH.
  #
  # ConditionPathExists keeps the unit inert (not failed, not looping) until a
  # video is actually in place, so a fresh checkout switches cleanly.
  systemd.user.services.mpvpaper = {
    Unit = {
      Description = "Video wallpaper on the 1080p panel";
      ConditionPathExists = "%h/Videos/wallpapers/live.mp4";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      # --auto-pause is supposed to stop decoding whenever the wallpaper is
      # covered, but measured on this machine it keeps decoding regardless.
      # hwdec=auto picks nvdec on the NVIDIA open driver.
      ExecStart = ''
        ${pkgs.mpvpaper}/bin/mpvpaper --auto-pause -o "no-audio loop-file=inf hwdec=auto panscan=1.0" "Dell Inc. DELL P2426H FHVRYD4" %h/Videos/wallpapers/live.mp4
      '';
      # mpvpaper is prone to dying on DPMS/mode changes; heal instead of going
      # black until it is noticed.
      Restart = "always";
      RestartSec = 5;
      # mpvpaper leaks ~1.13 GB/h — linearly, ~5 KB per decoded frame, forever.
      # Left alone it reached 10.7 GB after 9 hours. Measured A/B: the leak is
      # identical with hwdec=no (1.12 GB/h at 7x the CPU), so it is mpvpaper's
      # render loop, not the decoder, and no -o option fixes it. Recycling the
      # process is the only lever; a restart drops RSS straight back to ~335 MB.
      # Costs a ~5s black wallpaper on the 1080p panel every 2h (RestartSec above).
      RuntimeMaxSec = 7200;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
