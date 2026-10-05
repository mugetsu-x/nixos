{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kitty
    libnotify
    wl-clipboard
    wofi
    pamixer
    pavucontrol
    # waybar, mako and cliphist come from their home-manager modules.
    hyprpaper
    blueman
    networkmanagerapplet
    speedtest-cli
    grim
    slurp
    swappy
    spotify
    kdePackages.okular
    kdePackages.kio-extras
    ripgrep
    fd
    jq
    sops # edit secrets/*.yaml — see modules/secrets.nix
    age
    lazygit
    lazydocker
    fastfetch
    udiskie
    discord
    # Editors: Zed (home/modules/zed.nix) and Neovim (home/modules/neovim.nix).

    # Dolphin
    kdePackages.dolphin
    kdePackages.kio-fuse
    kdePackages.qtsvg
    kdePackages.ffmpegthumbs
    kdePackages.kimageformats
    kdePackages.kfilemetadata
    kdePackages.kdegraphics-thumbnailers
    kdePackages.ark
    p7zip
    unzip
    unrar
  ];
}
