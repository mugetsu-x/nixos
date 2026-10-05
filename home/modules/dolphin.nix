# home/modules/dolphin.nix
#
# Makes Dolphin (and every other KDE app) honour mimeapps.list outside Plasma.
#
# KDE apps never read mimeapps.list directly: they ask KService's sycoca
# cache, and kbuildsycoca only registers applications reachable through an
# XDG `applications.menu`. Plasma ships that file (plasma-applications.menu);
# bare Hyprland ships nothing, so the cache holds no applications at all —
# Dolphin's "Open With" is empty and double-click ignores the defaults set in
# swayimg.nix / media.nix, even though `xdg-mime query default` is correct.
#
# A hand-written catch-all menu instead of plasma-workspace's: that package is
# a large closure to carry for one XML file. It is installed under both names
# because kbuildsycoca looks for `${XDG_MENU_PREFIX}applications.menu`, and the
# Hyprland session sets XDG_MENU_PREFIX=Hyprland-.
#
# After a switch, the cache rebuilds on the next KDE app launch; to force it:
#   kbuildsycoca6 --noincremental
{ ... }:
let
  menu = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
      "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <Include><All/></Include>
    </Menu>
  '';
in
{
  xdg.configFile."menus/applications.menu".text = menu;
  xdg.configFile."menus/Hyprland-applications.menu".text = menu;
}
