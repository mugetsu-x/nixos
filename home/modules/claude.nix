{ config, ... }:
let
  # The repo's live working tree, not a /nix/store copy.
  repo = "${config.home.homeDirectory}/nixos-config";
in
{
  # Claude Code user config lives in this repo under claude/ and is symlinked
  # live into place with mkOutOfStoreSymlink. That means edits to a skill or to
  # settings land straight in the git working tree and are picked up
  # immediately — no rebuild needed to change *contents*, only to add or remove
  # a managed path here. A store copy (plain `source = ../..`) would be
  # read-only, which breaks Claude Code writing back to settings.json.
  #
  # Only these specific paths are managed; the rest of ~/.claude (credentials,
  # sessions, history, memory) is deliberately left untouched and untracked.
  home.file.".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "${repo}/claude/skills";

  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/claude/settings.json";

  # Workspace house rules shared by every project under ~/workspace.
  home.file."workspace/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/claude/workspace-CLAUDE.md";
}
