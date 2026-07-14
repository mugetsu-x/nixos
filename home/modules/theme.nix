{ config, pkgs, ... }: {
  fonts.fontconfig.enable = true;

  # Only essentials here; avoid adding papirus-icon-theme to prevent collisions.
  home.packages = with pkgs; [ jetbrains-mono noto-fonts-emoji qt6ct ];

  # Make Qt apps honor qt6ct (no Kvantum)
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    # (Optional: duplicate cursor envs for apps that read only env vars)
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  # Cursor
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;

    font = {
      name = "JetBrains Mono";
      size = 11;
    };

    # Catppuccin GTK (Macchiato, Blue).
    #
    # `name` must match a directory the package actually installs, and the
    # package only builds the variants it is overridden with — the default
    # build is frappe. The directory is named catppuccin-<variant>-<accent>-
    # <size>; there is no "-Dark" suffix and no capitals. Get the name wrong and
    # GTK silently falls back to Adwaita light, with no error anywhere.
    theme = {
      name = "catppuccin-macchiato-blue-standard";
      package = pkgs.catppuccin-gtk.override {
        variant = "macchiato";
        accents = [ "blue" ];
        size = "standard";
      };
    };

    # Catppuccin recolor of Papirus folders (Macchiato Blue)
    # Expose as "Papirus-Dark" so GTK & qt6ct can select it by name.
    iconTheme = {
      name = "Papirus-Dark"; # keep this in sync with qt6ct.conf below
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "macchiato"; # latte | frappe | macchiato | mocha
        accent = "blue"; # blue / rosewater / lavender / ...
      };
    };

    # Apps that ignore the theme and pick a light/dark variant themselves
    # (libadwaita, and GTK3 apps that check this hint) need to be told.
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  # The libadwaita-era equivalent of the hint above; read over D-Bus.
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # Catppuccin Macchiato Blue palette for Qt via qt6ct (Fusion style)
  xdg.dataFile."color-schemes/CatppuccinMacchiatoBlue.colors".text = ''
    [General]
    Name=Catppuccin Macchiato Blue
    ColorScheme=Catppuccin Macchiato Blue

    [Colors:View]
    BackgroundNormal=#24273a
    BackgroundAlternate=#1e2030
    ForegroundNormal=#cad3f5
    ForegroundInactive=#a5adcb
    ForegroundActive=#8aadf4
    ForegroundLink=#8aadf4
    ForegroundVisited=#b7bdf8
    DecorationFocus=#8aadf4
    DecorationHover=#8aadf4

    [Colors:Window]
    BackgroundNormal=#24273a
    ForegroundNormal=#cad3f5

    [Colors:Button]
    BackgroundNormal=#363a4f
    ForegroundNormal=#cad3f5
    ForegroundInactive=#a5adcb
    ForegroundActive=#8aadf4

    [Colors:Selection]
    BackgroundNormal=#8aadf4
    ForegroundNormal=#1e2030

    [Colors:Tooltip]
    BackgroundNormal=#1e2030
    ForegroundNormal=#cad3f5

    [Colors:Complementary]
    BackgroundNormal=#1e2030
    ForegroundNormal=#cad3f5
    DecorationFocus=#8aadf4
    DecorationHover=#8aadf4

    [Colors:Header]
    BackgroundNormal=#1e2030
    ForegroundNormal=#cad3f5

    [Colors:Header/Inactive]
    BackgroundNormal=#1e2030
    ForegroundNormal=#a5adcb
  '';

  # Pin qt6ct settings so Dolphin/Qt apps follow our icon + palette
  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    style=Fusion
    icon_theme=Papirus-Dark
    color_scheme_path=${config.xdg.dataHome}/color-schemes/CatppuccinMacchiatoBlue.colors

    [Fonts]
    fixed="JetBrains Mono,11,-1,5,50,0,0,0,0,0"
    general="JetBrains Mono,11,-1,5,50,0,0,0,0,0"

    [Interface]
    toolbutton_style=4
    toolbar_icon_size=24
    cursor_flash_time=1000
    double_click_interval=400
    wheel_scroll_lines=3
    underline_shortcut=1
    activate_item_on_single_click=0
    dialog_buttons_have_icons=1
  '';
}

