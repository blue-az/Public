---
id: pbc-messenger-core
title: Bulkhead τ Messenger — Behavior Contract (v2)
context: messenger-game
status: draft
updated: 2026-06-17
tags:
  - game
  - educational
  - bulkhead-tau
anchor: messenger-core
---

# Bulkhead τ Messenger — Behavior Contract

This charter defines the operational constraints for Bulkhead Messenger. Real-time telemetry is streamed to the Logbook sidebar. Corrective action requires physical attendance by the operator, but the vessel's voyage is prioritized as a stable, low-stress transit.

## Scope

- Engine fuel levels and efficiency (Engine Room)
- Navigation bearing and course drift (Bridge)
- Comms/Radio signal integrity (Radio Room)

## Rules

```pbc:rules
- id: PBC-MSG-001
  name: Engine Fuel Warning Threshold
  rule: Fuel levels below 20.0% signal a need for replenishment. Depleted fuel slows transit speed but does not result in loss.
  trust: trusted
  value: 20.0
  unit: percent
- id: PBC-MSG-002
  name: Course Drift Limit
  rule: Vessel bearing should deviate no more than 10.0 degrees. Higher drift slows progress as the navigator corrects the arc.
  trust: trusted
  value: 10.0
  unit: degrees
- id: PBC-MSG-003
  name: Comms Signal Quality
  rule: Comms array signal quality should remain above 30.0%. Poor signal reduces the efficiency of port-arrival handshakes.
  trust: trusted
  value: 30.0
  unit: percent
- id: PBC-MSG-004
  name: Calibrated Decay
  rule: Ship systems decay at a slow, staggered rate to ensure operator attention is focused on one maintenance task at a time.
  trust: trusted
```

## Behaviors

```pbc:behavior
id: MSG-BHV-001
name: System Decay
actor: ship-systems
description: Over time, ship systems decay at a calibrated, non-punishing rate.
trust: trusted
```

```pbc:outcomes
- System metrics (fuel level, bearing alignment, comms signal quality) slowly degrade over time.
```
```

```pbc:behavior
id: MSG-BHV-002
name: Physical Verification
actor: player
description: The operator walks to the corresponding console to perform a single-click verification and resolve the warning.
trust: trusted
```

```pbc:outcomes
- Warnings (fuel < 20%, drift > 10°, signal < 30%) trigger a single edge-triggered alarm and a log entry.
- Out-of-bounds systems reduce distance covered per tick.
- Correcting systems restores full transit speed.
```

## Provenance

```pbc:provenance
- ref: docs/BULKHEAD_MESSENGER_REDESIGN.md
  confidence: verified
  note: Redesign notes for the Messenger exploration containment demo.
- ref: bulkhead-messenger/index.html
  confidence: verified
  note: The Engine Room (game) implements explore-walk and console verification.
```
