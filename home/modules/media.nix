# home/modules/media.nix
#
# Default apps for PDFs and video. Images are in swayimg.nix. Like there, any
# type without an explicit default here silently falls through to Chrome.
{ lib, ... }:
let
  # Installed in packages.nix (it sits with the Dolphin/KDE group).
  okular = "org.kde.okular.desktop";
  mpv = "mpv.desktop";

  videoTypes = [
    "video/mp4"
    "video/x-matroska"
    "video/webm"
    "video/quicktime"
    "video/x-msvideo"
    "video/x-flv"
    "video/x-ms-wmv"
    "video/mpeg"
    "video/ogg"
    "video/3gpp"
    "video/3gpp2"
    "video/mp2t"
    "video/x-m4v"
  ];
in
{
  # mpv: Wayland-native, plays anything ffmpeg can. hwdec=auto-safe picks
  # NVDEC on the NVIDIA card and falls back to software for unsupported codecs.
  programs.mpv = {
    enable = true;
    config.hwdec = "auto-safe";
  };

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = [ okular ];
  }
  // lib.genAttrs videoTypes (_: [ mpv ]);
}
