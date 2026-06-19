---
id: pbc-damage-control-v3
title: Bulkhead Damage Control v3 — Ship Damage-Control Behavior Contract
context: damage-control-game
status: draft
updated: 2026-06-18
tags:
  - game
  - educational
  - bulkhead-tau
  - redesign
anchor: damage-control-v3
---

# Bulkhead Damage Control v3 — Ship Damage-Control Behavior Contract

A redesign so the game reads and plays like real ship damage control. v3 restores the
metaphor so the mechanics explain themselves: a hull with compartments, a visible
breach, watertight doors you race to close, and the sacrifice that keeps the ship
afloat. Everyone already holds the "ship is flooding, close the doors, save the
engine room" mental model — v3 just uses it. When v3 ships it replaces
`bulkhead-damage-control/damage-control.pbc.md` as the game's charter.

## Scope

- The vessel rendered as a recognizable ship (hull cross-section, waterline, keel compartments)
- Breaches as the visible source of flooding
- Watertight doors and the timed race to close them
- Containment as sacrifice (a sealed compartment is lost)
- Win and loss anchored on the critical core (Engine Room)

## Non-goals

- New domains or compartments beyond the existing set
- Changing the boundary lesson (still containment)
- Multiplayer or persistence

## Rules

```pbc:rules
- id: DC3-RUL-001
  name: Ship Cross-Section
  rule: The vessel must render as a recognizable hull cross-section with a waterline and compartments along the keel, not abstract columns.
  trust: trusted
  compartments: ["Tennis Agent", "GPS Oracle", "Water Report", "Proximity Sensor", "Engine Room"]
- id: DC3-RUL-002
  name: Visible Breach Is The Source
  rule: Water must enter a compartment only through a visible hull breach caused by a damage event, never from an unseen source.
  trust: trusted
  spread_rate: 0.05
  damage_frequency: 300
- id: DC3-RUL-003
  name: Watertight Doors
  rule: Adjacent compartments are separated by watertight doors that block flooding only while fully closed.
  trust: trusted
  sill: 0.25
- id: DC3-RUL-004
  name: Seal Race
  rule: Closing a door takes time; if water rises above the door sill before it closes the flood spills to the next compartment, otherwise it is contained.
  trust: trusted
  seal_duration: 180
- id: DC3-RUL-005
  name: Sealing Sacrifices The Compartment
  rule: A sealed-off flooded compartment is lost for the rest of the run and cannot be reopened or used.
  trust: trusted
- id: DC3-RUL-006
  name: Core Loss Condition
  rule: The ship founders the moment the Engine Room takes any water.
  trust: trusted
  critical_compartment: "Engine Room"
- id: DC3-RUL-007
  name: Win And Score
  rule: The player wins by surviving the target number of breaches with the Engine Room dry, and score is the count of compartments kept operational.
  trust: provisional
  waves_to_win: 4
```

## Behaviors

```pbc:behavior
id: DC3-BHV-001
name: Hull Breach
actor: environment
description: A damage event punches a visible hole in a compartment hull and water begins entering from it.
trust: trusted
```

```pbc:outcomes
- A breach is drawn at a real location on the hull and water rises from that hole.
- The player can see which compartment is taking on water and from where.
```

```pbc:behavior
id: DC3-BHV-002
name: Seal A Door
actor: player
description: The player closes a watertight door against a rising flood.
trust: trusted
```

```pbc:outcomes
- Closing before the water tops the sill contains the flood to that compartment.
- Closing too late lets the flood spill into the adjacent compartment.
- The closing animation reads as a watertight door, not a wall drawing upward.
```

```pbc:behavior
id: DC3-BHV-003
name: Sacrifice To Save The Core
actor: player
description: The player seals off flooding compartments to keep water away from the Engine Room.
trust: provisional
```

```pbc:outcomes
- A sealed compartment floods fully but is contained and counted as sacrificed.
- Sealing every compartment is not viable because each seal loses that compartment.
- The run is won when the Engine Room stays dry through the target number of breaches.
```

## Provenance

```pbc:provenance
- ref: docs/BULKHEAD_DAMAGE_CONTROL_REDESIGN.md
  confidence: verified
  note: The v2 containment redesign this builds on.
- ref: bulkhead-damage-control/index.html
  confidence: verified
  note: The current game whose abstract presentation v3 replaces with a ship.
- ref: docs/bulkhead-pbc-visibility.pbc.md
  confidence: verified
  note: v3 inherits the always-visible validation badge and rev requirements.
```
