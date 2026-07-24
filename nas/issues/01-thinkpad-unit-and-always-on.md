# 01 — Establish the ThinkPad's real specs and whether 24/7 headless is acceptable

Parent: [map](../map.md)
Type: grilling
Status: open
Blocked by: —

## Question

Two things the keystone (03) can't be decided without:

1. **What is this ThinkPad, exactly?** The specific unit's CPU, RAM (and max),
   dGPU (model + VRAM — matters for Immich ML and any video transcoding),
   internal storage (size, NVMe slots free), and NIC (2.5GbE?). "16p Gen 2"
   narrows the model class (research 02 fills the general picture), but only you
   can read off *this* machine's config.

2. **Is running it 24/7, headless, at home acceptable?** Where would it physically
   live (noise/heat near living space?), is the electricity cost tolerable
   (idle-watts from 02 × your kWh price), lid-closed operation, and is its
   battery effectively a built-in UPS you're happy to rely on? Or do you only
   want it powered on when needed (which pushes toward "secondary node", not
   "always-on server")?

Resolution records the concrete spec sheet and a clear yes/no/conditional on
always-on operation. This is HITL — it needs your answers, not a guess.
