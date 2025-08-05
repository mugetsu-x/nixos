{ config, pkgs, ... }: {
  home.username = "rennsemml";
  home.homeDirectory = "/home/rennsemml";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Zsh (optional — you can expand this later)
  programs.zsh.enable = true;

  # Kitty terminal config
  programs.kitty = {
    enable = true;

    font.name = "JetBrainsMono Nerd Font";
    font.size = 13;

    settings = {
      background_opacity = "0.8";
      hide_window_decorations = "yes";
      confirm_os_window_close = "0";
      enable_audio_bell = "no";

      cursor_shape = "beam";
      cursor_blink_interval = "0";

      map = [
        "ctrl+shift+c copy_to_clipboard"
        "ctrl+shift+v paste_from_clipboard"
      ];
    };

    extraConfig = builtins.readFile ./kitty/macchiato.conf;
  };
}
