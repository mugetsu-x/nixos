{ ... }:
{
  # sops-nix: secrets live encrypted in secrets/*.yaml (public repo — only
  # ciphertext is ever committed) and are decrypted at activation into
  # /run/secrets/<name>. Recipients are listed in .sops.yaml.
  #
  # main-pc has no sshd, hence no SSH host key to derive an age identity from,
  # so sops-nix generates a dedicated machine key on first activation. It never
  # leaves this machine; your personal age key (~/.config/sops/age/keys.txt) is
  # the one that is backed up and can re-encrypt everything.
  sops = {
    defaultSopsFile = ../secrets/main-pc.yaml;
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];

    # Round-trip check: `cat /run/secrets/canary` works as rennsemml, fails as
    # anyone else. Harmless; keep it as the first thing to test after key changes.
    secrets.canary = {
      owner = "rennsemml";
      mode = "0400";
    };
  };
}
