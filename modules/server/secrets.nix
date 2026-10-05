{ ... }:
{
  # Unlike main-pc, home-server runs sshd, so sops-nix decrypts with its ed25519
  # SSH host key (the default once openssh is on). Its age form is the
  # recipient in .sops.yaml. Nothing extra to back up: after a reinstall, enrol
  # the new host key and `sops updatekeys secrets/home-server.yaml`.
  sops = {
    defaultSopsFile = ../../secrets/home-server.yaml;
    gnupg.sshKeyPaths = [ ];

    # Round-trip check, as on main-pc: `cat /run/secrets/canary` works as
    # rennsemml and nobody else.
    secrets.canary = {
      owner = "rennsemml";
      mode = "0400";
    };
  };
}
