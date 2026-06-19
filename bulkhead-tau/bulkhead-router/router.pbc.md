---
id: pbc-router-core
title: Bulkhead τ Router — Behavior Contract
context: router-game
status: draft
updated: 2026-06-17
tags:
  - game
  - educational
  - bulkhead-tau
anchor: router-core
---

# Bulkhead τ Router — Behavior Contract

This charter defines the Data Boundary for ship ingress. Untrusted data packets must be validated against schema rules before being routed to trusted subsystem lanes.

## Scope

- Packet ingress and schema validation
- Routing mechanics (Subsystems vs. Quarantine)
- Deterministic stream generation

## Rules

```pbc:rules
- id: PBC-RTR-001
  name: Known Destination
  rule: Packet type must be one of ENGINE, BRIDGE, COMMS, or LIFE_SUPPORT before it may be routed.
  trust: trusted
- id: PBC-RTR-002
  name: Checksum Shape
  rule: Packet checksum must be exactly four uppercase hexadecimal characters.
  trust: trusted
- id: PBC-RTR-003
  name: TTL Range
  rule: Packet ttl must be an integer from 1 through 9.
  trust: trusted
- id: PBC-RTR-004
  name: Priority Range
  rule: Packet priority must be an integer from 1 through 5.
  trust: trusted
- id: PBC-RTR-005
  name: Payload Allowlist
  rule: Packet payload must match the allowlist for its destination subsystem.
  trust: trusted
- id: PBC-RTR-006
  name: Poison Quarantine
  rule: Any packet violating a schema rule must be routed to QUARANTINE, not to a subsystem lane.
  trust: trusted
- id: PBC-RTR-007
  name: Deterministic Packet Stream
  rule: Packet generation and outcomes must be deterministic for the same seed and same input sequence.
  trust: trusted
- id: PBC-RTR-008
  name: Runtime Validation
  rule: Route outcomes must be computed from the packet fields at decision time, not from a hidden precomputed poison flag.
  trust: trusted
```

## Allowlist Definitions

- **ENGINE:** `injector_trim:+1`, `injector_trim:+2`, `coolant_pump:on`, `fuel_mix:lean`
- **BRIDGE:** `course_hold:on`, `rudder_trim:-1`, `rudder_trim:+1`, `bearing_sync`
- **COMMS:** `ping:harbor`, `sync:beacon`, `antenna_gain:+1`, `packet_ack`
- **LIFE_SUPPORT:** `oxygen_mix:nominal`, `scrubber:on`, `pressure_check`, `filter_cycle`

## Behaviors

```pbc:behavior
id: RTR-BHV-001
name: Route Packet
actor: operator
description: The operator routes an incoming packet to a destination lane or quarantine.
trust: trusted
```

```pbc:outcomes
- Valid packet + Matching lane: Score increase, log 'ROUTED'.
- Valid packet + Wrong lane: Integrity damage, log 'MISROUTE'.
- Poisoned packet + Quarantine: Score increase, log 'QUARANTINED' with rule ID.
- Poisoned packet + Subsystem: Large integrity damage, log 'SCHEMA BREACH'.
- Valid packet + Quarantine: Throughput and minor integrity penalty, log 'FALSE POSITIVE'.
```

## Provenance

```pbc:provenance
- ref: docs/BULKHEAD_ROUTER_SPEC.md
  confidence: verified
  note: Specifications for the Router schema boundary demo.
- ref: bulkhead-router/index.html
  confidence: verified
  note: The Engine Room (game) parses these rules/schema at runtime.
```
