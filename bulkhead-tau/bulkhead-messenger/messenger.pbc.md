---
id: pbc-messenger-core
title: Bulkhead τ Messenger — Behavior Contract
context: messenger-game
status: draft
updated: 2026-06-16
tags:
  - game
  - educational
  - bulkhead-tau
anchor: messenger-core
---

# Bulkhead τ Messenger — Behavior Contract

This charter defines the operational constraints and physical verification protocols for Bulkhead Messenger. Real-time telemetry is streamed to the Logbook sidebar, but corrective action requires physical attendance by the operator.

## Scope

- Engine fuel levels and efficiency (Engine Room)
- Navigation bearing and course drift (Bridge)
- Comms/Radio signal integrity and message dispatch (Radio Room)

## Rules

```pbc:rules
- id: PBC-MSG-001
  name: Engine Fuel Warning Threshold
  rule: Fuel levels must remain above 20.0% to avoid propulsion failure.
  trust: trusted
  value: 20.0
  unit: percent
- id: PBC-MSG-002
  name: Course Drift Limit
  rule: Vessel bearing must deviate no more than 10.0 degrees from the charted course.
  trust: trusted
  value: 10.0
  unit: degrees
- id: PBC-MSG-003
  name: Comms Signal Quality
  rule: Comms array signal quality must remain above 30.0% for stable transmissions.
  trust: trusted
  value: 30.0
  unit: percent
- id: PBC-MSG-004
  name: Physical Attendance Protocol
  rule: Audited alarms can only be cleared by direct physical console interaction, preventing remote-clearing hallucinations.
  trust: trusted
```

## Behaviors

```pbc:behavior
id: MSG-BHV-001
name: System Decay
actor: ship-systems
description: Over time, ship systems decay (fuel depletes, course drifts, radio frequency drifts).
trust: trusted
```

```pbc:behavior
id: MSG-BHV-002
name: Physical Verification
actor: player
description: The sailor walks to the corresponding console to perform verification and resolve the warning.
trust: trusted
```

```pbc:outcomes
- If fuel < 20%, course drift > 10°, or radio signal < 30%, a warning is appended to the Logbook.
- Standing inside the station's zone allows console access to correct the state.
- Successful verification resets the system state and logs a 'VERIFIED' event in the Logbook.
```
