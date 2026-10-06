# 18 — Home Assistant (smart home)

**What to build:** [Home Assistant](https://www.home-assistant.io) on `home-server`
as the hub for whatever smart-home devices exist now or arrive later.

Added 2026-10-06 as a wish (Walter); **not grilled yet**. This is the ticket with
the most open questions. Start with the device inventory.

**The big decision: how to run it.** Each option costs something:

| Option | Gets you | Costs |
|---|---|---|
| nixpkgs `services.home-assistant` | declarative, integrations as Nix packages | every integration's Python deps must be in nixpkgs; no add-ons; config partly in Nix, partly in the UI |
| `oci-containers` (official image) | matches upstream exactly, same pattern as the other services | no add-ons (no Supervisor), updates by tag bump |
| Home Assistant OS in a VM | add-on store, the "official" experience | a whole VM on the laptop, USB passthrough, outside Nix entirely |

Add-ons (Zigbee2MQTT, Mosquitto, ESPHome, ...) can all run as separate containers
next to a container or Nix install. So "no add-ons" means wiring them yourself, not
going without.

**Things that will bite:**
- **Discovery needs host networking** (mDNS/SSDP/HomeKit). That's the existing
  pattern here anyway, but it means opening the right ports in the firewall
  deliberately.
- **Radios:** Zigbee/Thread/Z-Wave need a USB coordinator plugged into the
  laptop. That's a fixed physical dependency on the box, and its device path must
  be stable (`/dev/serial/by-id/…`).
- The **mobile app** wants HTTPS for remote use. Same TLS question as
  [17](17-actual-budget.md): settle it once.
- The laptop's battery covers short outages, which suits a smart-home hub. Long
  outages still need the power button (06).

**Open questions:**
- What devices exist today (brands, protocols: Wi-Fi, Zigbee, Matter/Thread,
  Bluetooth)? What's planned?
- Which install option (table above)?
- Does Anja use it too? Dashboards and phone presence for both?

**Backup:** the config directory (`/var/lib/hass` or equivalent) goes into
[13](13-restic-321-service.md). Automations and device pairings are painful to
recreate.

**Blocked by:** 06, 08. The TLS answer (see 17) is needed for remote app use.

**Status:** idea, not grilled
