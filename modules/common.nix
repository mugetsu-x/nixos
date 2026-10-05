{ config, pkgs, ... }:

{
  # main-pc's desktop layer on top of base.nix.
  networking.networkmanager.enable = true;

  # kitty lives in home/modules/packages.nix; git is in base.nix.

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  users.users.rennsemml.extraGroups = [ "networkmanager" ];

  programs.dconf.enable = true;

  # Bluetooth stack
  hardware.firmware = [ pkgs.linux-firmware ];
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = { Experimental = true; };
      Policy = { AutoEnable = true; };
    };
  };

  # The altgr-intl variant (set in base.nix) puts ä/ö/ü/ß on the third level of
  # q/p/y/s, reached by holding Right Alt. Windows also accepts Ctrl+Alt as a
  # stand-in for AltGr; xkb does not — every lv3: option is a single key — so the
  # Keychron Q8 Pro needs a real Right Alt in its firmware (Fn2 remapped to
  # KC_RALT via the Keychron Launcher). These udev rules are what let the browser
  # reach the board over WebHID; without them the Launcher shows no keyboard at all.
  hardware.keyboard.qmk.enable = true;

  # qmk-udev-rules assigns GROUP="plugdev", which NixOS does not create. Access
  # actually comes from the rules' TAG+="uaccess", but without the group udev
  # logs an unknown-group error for every HID device on the system.
  users.groups.plugdev = { };

  services.blueman.enable = true;

  # udiskie (home/modules/services.nix) talks to the UDisks2 D-Bus service, which
  # nothing else pulls in since we are not running a full desktop environment.
  services.udisks2.enable = true;

  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  security.rtkit.enable = true;
}
