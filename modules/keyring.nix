{ pkgs, ... }:
{
  # A Secret Service provider (the D-Bus name org.freedesktop.secrets).
  #
  # Zed stores API keys for its agent there, and without a provider it fails at
  # startup with "Failed to authenticate provider: Anthropic: DBus error ... The
  # name is not activatable" — the agent then cannot save credentials at all.
  # A full desktop would ship one; bare Hyprland does not.
  #
  # kwalletd6 is on the system already (pulled in by the KDE/Dolphin packages)
  # but it does not claim the freedesktop name, so it does not help here.
  services.gnome.gnome-keyring.enable = true;

  # Unlock the keyring with the login password instead of prompting again on
  # first use. greetd is the display manager (see login.nix), so the PAM stanza
  # has to go on *its* service — putting it on "login" would do nothing.
  security.pam.services.greetd.enableGnomeKeyring = true;

  # GUI to inspect/clear stored secrets when something looks wrong.
  environment.systemPackages = [ pkgs.seahorse ];
}
