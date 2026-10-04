# home/modules/swayimg.nix
#
# Image viewer. Until this module there was none: `xdg-mime query default
# image/png` answered `com.google.Chrome.desktop`, not because chrome.nix claims
# image types (it claims only html/http/https/mailto) but because Chrome was the
# only installed .desktop declaring them at all.
#
# Why swayimg and not imv: nixpkgs builds imv without freeimage, which leaves it
# with no webp and no bmp backend — the two formats a browser drops on disk most
# often. swayimg links libwebp, libavif, libheif, libjxl, librsvg, libraw,
# openexr and giflib, so it opens everything that lands in ~/Downloads. It is
# also Wayland-only (no X11 path to fall back through) and has a gallery mode.
{ lib, pkgs, ... }:
let
  # swayimg.desktop ships NoDisplay=true, so it is unreachable from wofi and is
  # only ever entered by opening a file — which makes the mime defaults below
  # the entire integration surface.
  swayimg = "swayimg.desktop";

  # Kept to formats swayimg actually has a decoder for. Anything absent here
  # keeps falling through to Chrome, which is the right answer for e.g. ico.
  imageTypes = [
    "image/png"
    "image/jpeg"
    "image/gif"
    "image/webp"
    "image/avif"
    "image/heif"
    "image/heic"
    "image/jxl"
    "image/tiff"
    "image/bmp"
    "image/x-bmp"
    "image/svg+xml"
    "image/x-exr"
    "image/x-tga"
    "image/x-portable-anymap"
    "image/x-portable-bitmap"
    "image/x-portable-graymap"
    "image/x-portable-pixmap"
  ];
in
{
  home.packages = [ pkgs.swayimg ];

  # Raw dotfile, same deal as hypr/kitty/waybar: colours and keybinds are edited
  # in place, no rebuild.
  xdg.configFile."swayimg/config".source = ../dotfiles/swayimg/config;

  # Merges with the html/http/https/mailto block in chrome.nix — different keys,
  # so home-manager combines them into one mimeapps.list.
  xdg.mimeApps.defaultApplications = lib.genAttrs imageTypes (_: [ swayimg ]);
}
