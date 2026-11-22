{ pkgs, ... }:
{
  # xps13's half of the desktop config. wayland.nix links everything the hosts
  # share; these are the files that name the laptop's panel and input devices.
  xdg.configFile."hypr/host.conf".source = ../dotfiles/hosts/xps13/hyprland.conf;
  xdg.configFile."hypr/hyprpaper.conf".source = ../dotfiles/hosts/xps13/hyprpaper.conf;
  xdg.configFile."waybar/config.jsonc".source = ../dotfiles/hosts/xps13/waybar.jsonc;

  # See wayland.nix for why these units restart when their files change.
  systemd.user.services.waybar.Unit.X-Restart-Triggers = [
    "${../dotfiles/hosts/xps13/waybar.jsonc}"
  ];
  systemd.user.services.hyprpaper.Unit.X-Restart-Triggers = [
    "${../dotfiles/hosts/xps13/hyprpaper.conf}"
  ];

  # hyprpaper.conf and hyprlock.conf both point at this path. On main-pc the
  # file was put there by hand; here it comes from the repo, so a fresh install
  # has a wallpaper.
  home.file."Pictures/wallpapers/hole.jpeg".source = ../dotfiles/hypr/wallpapers/hole.jpeg;

  # Drives the brightness keys bound in the host's hyprland.conf and waybar's
  # backlight module. It asks logind to set the brightness, so it needs no
  # group membership or udev rule.
  home.packages = [ pkgs.brightnessctl ];
}
