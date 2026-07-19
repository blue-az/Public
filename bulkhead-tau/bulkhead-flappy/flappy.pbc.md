---
id: pbc-flappy-core
title: Bulkhead Flappy Ship — Playable Core Charter
context: flappy-game
status: draft
updated: 2026-06-12
tags:
  - game
  - educational
  - bulkhead-tau
  - flappy-ship
anchor: flappy-core
---

# Bulkhead Flappy Ship — Playable Core Charter

This charter defines the behavior contract for the Bulkhead Flappy Ship game. The Engine Room must provably enforce these constants and behaviors.

## Scope

- Vessel physics (current acceleration, thrust)
- Obstacle generation and movement (bulkheads)
- Collision and scoring rules

## Rules

```pbc:rules
- id: FLPY-RUL-001
  name: Current Constant
  rule: The vessel is subject to a constant current acceleration. Base value is 0.25; acceptable operational range is 0.15 to 0.40 in magnitude (positive or negative).
  trust: trusted
  value: 0.25
  min: 0.15
  max: 0.40
- id: FLPY-RUL-001b
  name: Deterministic Execution
  rule: The engine must produce identical outcomes given the same initial seed and input sequence (Logbook-ready).
  trust: trusted
- id: FLPY-RUL-002
  name: Thrust Impulse
  rule: A user input triggers an immediate velocity change of 5 pixels per frame opposite to the current direction.
  trust: trusted
  value: -5
- id: FLPY-RUL-003
  name: Safe Envelope (Gap)
  rule: Each bulkhead must maintain a vertical gap of exactly 160 pixels for safe passage.
  trust: trusted
  value: 160
- id: FLPY-RUL-004
  name: Flow Speed
  rule: Bulkhead obstacles move from right to left at a constant speed of 3 pixels per frame.
  trust: trusted
  value: 3
- id: FLPY-RUL-005
  name: Obstacle Density
  rule: Bulkhead obstacles are spaced at a horizontal interval of 250 pixels.
  trust: trusted
  value: 250
- id: FLPY-RUL-006
  name: Collision Boundary
  rule: Collision occurs if the vessel bounding box intersects a bulkhead structure or leaves the vertical channel (0 to 640 pixels).
  trust: trusted
- id: FLPY-RUL-007
  name: Destination Gate Count
  rule: A run ends in success after the configured number of gates is cleared. The default destination is 10 gates; the playable charter range is 5 to 30 gates.
  trust: trusted
  value: 10
  min: 5
  max: 30
```

## Behaviors

```pbc:behavior
id: FLPY-BHV-001
name: Vessel Thrust
actor: pilot
description: The pilot applies thrust to counteract the current.
trust: trusted
```

```pbc:outcomes
- Vessel velocity is set to 5 in direction opposite to current.
```

```pbc:behavior
id: FLPY-BHV-002
name: Engine Update
actor: engine_room
description: The engine updates the world state based on physical constants.
trust: trusted
```

```pbc:outcomes
- Vessel velocity increases by 0.25 (CURRENT).
- Vessel position Y increases by velocity.
- Bulkhead position X decreases by 3 (FLOW_SPEED).
```

## Provenance

```pbc:provenance
- ref: docs/BULKHEAD_FLAPPY_REQUIREMENTS.md
  confidence: verified
  note: Requirements spec for the Flappy containment demo.
- ref: bulkhead-flappy/index.html
  confidence: verified
  note: The Engine Room (game) parses these constants at runtime.
```
