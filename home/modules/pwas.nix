{ config, pkgs, ... }: {
  xdg.desktopEntries = {
    teams-pwa = {
      name = "Microsoft Teams";
      genericName = "Teams";
      comment = "Microsoft Teams (PWA)";
      exec =
        "google-chrome-stable --ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations --app=https://teams.microsoft.com";
      terminal = false;
      # Main = Network; extra = InstantMessaging (registered)
      categories = [ "Network" "InstantMessaging" ];
      icon = "internet-chat";
    };

    outlook-pwa = {
      name = "Microsoft Outlook";
      genericName = "Outlook Mail";
      comment = "Microsoft Outlook (PWA)";
      exec =
        "google-chrome-stable --ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations --app=https://outlook.office.com/mail/";
      terminal = false;
      # Main = Office; extra = Email (registered). Avoid a second main like Network.
      categories = [ "Office" "Email" ];
      icon = "mail-client";
    };

    monday-pwa = {
      name = "monday.com";
      genericName = "Project Management";
      comment = "monday.com (PWA)";
      exec =
        "google-chrome-stable --ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations --app=https://app.monday.com/";
      terminal = false;
      # Main = Office; custom category must be prefixed with X-
      categories = [ "Office" "X-ProjectManagement" ];
      icon = "applications-office";
    };

    notion-pwa = {
      name = "Notion";
      genericName = "Notion";
      comment = "Notion (PWA)";
      exec =
        "google-chrome-stable --ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations --app=https://www.notion.so/";
      terminal = false;
      # Keep it simple and valid: main = Office (you can add a custom X- tag if you like)
      categories = [ "Office" ];
      icon = "accessories-text-editor";
    };

    gemini-pwa = {
      name = "Google Gemini";
      genericName = "AI Assistant";
      comment = "Google Gemini (Isolated PWA)";
      # We interpolate the home directory here using Nix
      exec =
        "google-chrome-stable --ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations --app=https://gemini.google.com/app --user-data-dir=${config.home.homeDirectory}/.config/google-chrome-gemini";
      terminal = false;
      categories = [ "Development" "Science" "X-ArtificialIntelligence" ];
      icon = "google-chrome";
    };
  };
}

