---
id: pbc-flappy-core
title: Bulkhead Flappy — Playable Core Charter
context: flappy-game
status: draft
updated: 2026-06-12
tags:
  - game
  - educational
  - bulkhead-tau
anchor: flappy-core
---

# Bulkhead Flappy — Playable Core Charter

This charter defines the behavior contract for the Bulkhead Flappy game. The Engine Room must provably enforce these constants and behaviors.

## Scope

- Vessel physics (gravity, thrust)
- Obstacle generation and movement (bulkheads)
- Collision and scoring rules

## Rules

```pbc:rules
- id: FLPY-RUL-001
  name: Gravity Constant
  rule: The vessel is subject to a constant downward acceleration. Base value is 0.25; acceptable operational range is 0.15 to 0.40.
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
  rule: A user input triggers an immediate upward velocity change of -5 pixels per frame.
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
```

## Behaviors

```pbc:behavior
id: FLPY-BHV-001
name: Vessel Thrust
actor: pilot
description: The pilot applies thrust to counteract gravity.
trust: trusted
```

```pbc:outcomes
- Vessel velocity is set to -5 (THRUST_IMPULSE).
```

```pbc:behavior
id: FLPY-BHV-002
name: Engine Update
actor: engine_room
description: The engine updates the world state based on physical constants.
trust: trusted
```

```pbc:outcomes
- Vessel velocity increases by 0.25 (GRAVITY).
- Vessel position Y increases by velocity.
- Bulkhead position X decreases by 3 (FLOW_SPEED).
```
