---
id: pbc-damage-control-core
title: Bulkhead Damage Control — Playable Core Charter
context: damage-control-game
status: draft
updated: 2026-06-15
tags:
  - game
  - educational
  - bulkhead-tau
anchor: damage-control-core
---

# Bulkhead Damage Control — Playable Core Charter

This charter defines the behavior contract for the Bulkhead Damage Control game. The Engine Room must provably enforce these constants and behaviors.

## Scope

- Hull compartments and bulkhead doors
- Flood dynamics and spread
- Sealing mechanics and containment rules

## Rules

```pbc:rules
- id: DC-RUL-001
  name: Flood Spread Rate
  rule: Water spreads to an adjacent compartment through an OPEN bulkhead door at a rate of 0.05 volume units per frame (60fps).
  trust: trusted
  value: 0.05
- id: DC-RUL-002
  name: Seal Duration
  rule: Sealing a bulkhead door takes exactly 180 frames (3 seconds at 60fps).
  trust: trusted
  value: 180
- id: DC-RUL-003
  name: Max Floods Lose Threshold
  rule: The vessel sinks if 3 or more compartments reach 1.0 (100%) flood volume.
  trust: trusted
  value: 3
- id: DC-RUL-004
  name: Critical Compartment
  rule: The Engine Room must remain at 0.0 flood volume. Any flooding in the Engine Room results in an immediate loss.
  trust: trusted
  value: "Engine Room"
- id: DC-RUL-005
  name: Compartment Layout
  rule: The vessel consists of 5 linear compartments, ordered bow-to-stern — Tennis Agent, GPS Oracle, Water Report, Proximity Sensor, Engine Room.
  trust: trusted
  value: ["Tennis Agent", "GPS Oracle", "Water Report", "Proximity Sensor", "Engine Room"]
- id: DC-RUL-006
  name: Damage Event Frequency
  rule: A new damage event (leak) occurs every 600 frames (10 seconds) in a random non-Engine-Room compartment.
  trust: trusted
  value: 600
- id: DC-RUL-007
  name: Deterministic Execution
  rule: The engine must produce identical outcomes given the same initial seed and input sequence (Logbook-ready).
  trust: trusted
```

## Behaviors

```pbc:behavior
id: DC-BHV-001
name: Seal Bulkhead
actor: operator
description: The operator initiates the sealing of a bulkhead door.
trust: trusted
```

```pbc:outcomes
- Bulkhead door state enters 'SEALING' mode.
- Door is fully 'CLOSED' after 180 frames (SEAL_DURATION).
- While 'SEALING' or 'OPEN', water can still pass.
- Once 'CLOSED', water flow between compartments is blocked.
```

```pbc:behavior
id: DC-BHV-002
name: Flood Propagation
actor: engine_room
description: The engine updates flood levels and spreads water through open doors.
trust: trusted
```

```pbc:outcomes
- If a compartment has water and an adjacent bulkhead is 'OPEN', water volume transfers at 0.05 (SPREAD_RATE) until levels equalize.
- Compartment flood level increases by 0.01 per frame if it has an active leak.
```

## Provenance

```pbc:provenance
- ref: docs/BULKHEAD_DAMAGE_CONTROL_REQUIREMENTS.md
  confidence: verified
  note: Requirements spec for the damage-control containment demo; defines the compartment-as-domain / bulkhead-as-policy-boundary mapping the game enacts.
- ref: bulkhead-damage-control/index.html
  confidence: verified
  note: The Engine Room (game) parses these constants at runtime via regex; sealed bulkheads provably block flood spread and a seeded input log replays bit-identical (verified by code inspection 2026-06-15).
```
