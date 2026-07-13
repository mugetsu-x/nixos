{ ... }: {
  # nh wraps nixos-rebuild and shows a diff of what is about to change before it
  # switches. NH_FLAKE points at this repo, so `nh os switch` works from any
  # directory, with no --flake argument.
  programs.nh = {
    enable = true;
    flake = "/home/rennsemml/nixos-config";

    # nh.clean stays off on purpose: nix.gc in common.nix already collects
    # garbage weekly, and enabling both makes nh warn about the conflict.
  };

  # `, cowsay hi` runs a program without installing it, and `nix-locate bin/foo`
  # answers "which package provides this binary". Both need the nix-index
  # database, which comes prebuilt from the nix-index-database flake input.
  programs.nix-index-database.comma.enable = true;
}
