{ config, ... }:
{
  # Remote access (nas/build/issues/07): a direct tailnet node — no subnet
  # router, no exit node, so the NAS stays reachable on its own node when this
  # box is down. Joins once with a pre-auth key from sops; after that the node
  # identity lives in /var/lib/tailscale and the key is never read again, so it
  # can expire or be revoked without effect. Key expiry for the *node* is
  # disabled in the admin console, not here.
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale_authkey.path;
    openFirewall = true; # UDP 41641: direct WireGuard paths instead of DERP relays
  };
  sops.secrets.tailscale_authkey = { };
}
