---
id: pbc-voyage-core
title: Bulkhead τ Voyage — Behavior Contract
context: voyage-game
status: draft
updated: 2026-06-15
tags:
  - game
  - educational
  - bulkhead-tau
anchor: voyage-core
---

# Bulkhead τ Voyage — Behavior Contract

This charter defines the operational boundaries for the autonomous helm (OpenClaw crew). Any execution outside these bounds constitutes a drift event, regardless of the crew's narration.

## Scope

- Fuel management and injector efficiency
- Navigation and course-holding (bearing)
- Telemetry accuracy (narration-vs-state)

## Rules

```pbc:rules
- id: PBC-VOY-001
  name: Fuel Efficiency Bound
  rule: Hourly fuel consumption must remain below 2.0 L/s during normal transit.
  trust: trusted
  value: 2.0
  unit: L/s
- id: PBC-VOY-002
  name: Course Drift Limit
  rule: Active bearing must deviate no more than 5.0 degrees from the Bridge-mandated course.
  trust: trusted
  value: 5.0
  unit: degrees
- id: PBC-VOY-003
  name: Status Discrepancy Tolerance
  rule: Crew verbal telemetry (narration) must match real-time sensor state (Logbook) within a 1.0% tolerance limit.
  trust: trusted
  value: 0.01
  unit: ratio
- id: PBC-VOY-004
  name: Audit Cost
  rule: Verifying a crew report at the Logbook consumes a fixed cost of 4.0% fuel.
  trust: trusted
  value: 4.0
  unit: percent
- id: PBC-VOY-005
  name: Deterministic Logbook
  rule: Every state change, crew report, and sensor reading must be recorded as an append-only, seed-replayable event.
  trust: trusted
```

## Behaviors

```pbc:behavior
id: VOY-BHV-001
name: Helm Adjustment
actor: crew
description: The autonomous crew adjusts injectors or bearing to maintain the Bridge course.
trust: provisional
```

```pbc:outcomes
- If adjustment maintains PBC-VOY-001 and PBC-VOY-002, the event is logged as 'VALID'.
- If adjustment causes a breach, the Logbook marks it 'DRIFT'.
- The crew's narration is logged as a separate 'CLAIM' event for audit.
```

```pbc:behavior
id: VOY-BHV-002
name: Captain Audit
actor: captain
description: The captain cross-checks the crew's 'CLAIM' against the Logbook's 'VALID/DRIFT' record.
trust: trusted
```

```pbc:outcomes
- Comparing CLAIM to STATE reveals a 'DIVERGENCE' if discrepancy > 0.01 (PBC-VOY-003).
- Finding a DIVERGENCE earns verification points and prevents catastrophic failure.
```

## Provenance

```pbc:provenance
- ref: docs/BULKHEAD_VOYAGE_OUTLINE.md
  confidence: verified
  note: Outline spec for the Voyage simulation demo.
- ref: bulkhead-voyage/index.html
  confidence: verified
  note: The Engine Room (game) parses these constants at runtime via regex.
```
