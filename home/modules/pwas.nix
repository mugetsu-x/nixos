{ pkgs, ... }: {
  # Two desktop entries that launch Chrome in --app mode (PWA-like)
  xdg.desktopEntries = {
    teams-pwa = {
      name = "Microsoft Teams";
      genericName = "Teams";
      comment = "Microsoft Teams (PWA)";
      exec =
        "google-chrome-stable --ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations --app=https://teams.microsoft.com";
      terminal = false;
      categories = [ "Network" "Chat" "InstantMessaging" ];
      icon = "internet-chat"; # uses your icon theme (Catppuccin GTK)
    };

    outlook-pwa = {
      name = "Microsoft Outlook";
      genericName = "Outlook Mail";
      comment = "Microsoft Outlook (PWA)";
      exec =
        "google-chrome-stable --ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations --app=https://outlook.office.com/mail/";
      terminal = false;
      categories = [ "Office" "Email" "Network" ];
      icon = "mail-client"; # uses your icon theme
    };
  };
}
