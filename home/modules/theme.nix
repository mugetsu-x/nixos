{ pkgs, ... }: {
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [ jetbrains-mono noto-fonts-emoji ];

  gtk.enable = true;
  gtk.font = {
    name = "JetBrains Mono";
    size = 11;
  };

  # optional: re-enable Catppuccin GTK theme
  gtk.theme = {
    name = "Catppuccin-Macchiato-Standard-Blue-Dark";
    package = pkgs.catppuccin-gtk;
  };
}

