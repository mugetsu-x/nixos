# home/modules/chrome.nix
{ pkgs, ... }: {
  # Install Chrome (needs allowUnfree=true — you already have that)
  home.packages = [ pkgs.google-chrome ];

  # Create a local .desktop that forces Wayland flags
  # This overrides the upstream ID ("google-chrome.desktop")
  xdg.desktopEntries.google-chrome = {
    name = "Google Chrome";
    genericName = "Web Browser";
    exec = "google-chrome-stable --ozone-platform-hint=wayland %U";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [
      "text/html"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/mailto"
    ];
  };

  # Make Chrome the default opener for web links/files
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "google-chrome.desktop" ];
    "x-scheme-handler/http" = [ "google-chrome.desktop" ];
    "x-scheme-handler/https" = [ "google-chrome.desktop" ];
    "x-scheme-handler/mailto" = [ "google-chrome.desktop" ];
  };
}

