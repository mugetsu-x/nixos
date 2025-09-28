{ pkgs, ... }: {
  home.packages = with pkgs; [
    kitty
    libnotify
    wl-clipboard
    cliphist
    wofi
    mako
    pamixer
    pavucontrol
    waybar
    hyprpaper
    blueman
    networkmanagerapplet
    speedtest-cli
    grim
    slurp
    swappy
    spotify
    kdePackages.okular
    kdePackages.kimageformats
    kdePackages.kio-extras
    ripgrep
    fd
    jq
    lazygit
    lazydocker
    fastfetch
    udiskie
    discord

    # Dolhin
    kdePackages.dolphin
    kdePackages.kio-extras
    kdePackages.kio-fuse
    kdePackages.qtsvg
    kdePackages.ffmpegthumbs
    kdePackages.kimageformats
    kdePackages.kfilemetadata
    kdePackages.kdegraphics-thumbnailers
    qt6ct
    kdePackages.ark
    p7zip
    unzip
    unrar
  ];
}
