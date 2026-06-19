---
id: pbc-voyage-messenger-core
title: Bulkhead τ Voyage-Messenger — Behavior Contract
context: voyage-messenger-game
status: draft
updated: 2026-06-18
tags:
  - game
  - educational
  - bulkhead-tau
anchor: voyage-messenger-core
---

# Bulkhead τ Voyage-Messenger — Behavior Contract

This charter defines the operational constraints for Bulkhead Voyage-Messenger. It combines spatial movement (physically attending consoles) with cognitive verification (auditing automated crew reports against the raw logbook substrate).

## Scope

- Spatial navigation of the operator drone
- System decay monitoring (Engine Fuel, Navigation Bearing, Comms Signal)
- Supervisor Audit console interaction (Trust vs. Verify paths)

## Rules

```pbc:rules
- id: PBC-VM-001
  name: Physical Attendance
  rule: Enforcing calibration or running audits requires the operator to physically stand on the console's interactive pad.
  trust: trusted
- id: PBC-VM-002
  name: Audit Triage Cost
  rule: Consulting the raw Logbook substrate consumes resources (-4.0% Fuel / Signal / Alignment energy) depending on the console.
  trust: trusted
  value: 4.0
- id: PBC-VM-003
  name: Crew Drift Variance
  rule: Automated crew reports may diverge from ground truth. Trusting a false report results in hidden fuel leakages or alignment faults.
  trust: provisional
- id: PBC-VM-004
  name: Speed Enforcement Boundary
  rule: System warning states (Fuel < 20%, Drift > 10°, Signal < 30%) degrade transit speed. Transit halts if fuel is exhausted, drift reaches 30°, or signal drops to 0%.
  trust: trusted
```

## Allowlist / Audit Templates

Audits evaluate reports against the following ground-truth boundaries:
- **Engine Fuel:** Consumption must remain below **2.0 L/s**.
- **Navigation Bearing:** Course Drift must remain below **5.0°**.
- **Comms Signal:** Transmission noise must remain below **0.01%**.

## Behaviors & Outcomes

```pbc:behavior
id: VM-BHV-001
name: System Decay
actor: ship-systems
description: Over time, systems decay. Warnings slow transit velocity down.
trust: trusted
```

```pbc:behavior
id: VM-BHV-002
name: Audit Decision
actor: player
description: The operator stands on a console pad and chooses to Trust the Crew or Verify at the Logbook.
trust: trusted
```

```pbc:outcomes
- Selecting TRUST on an honest report: Cleans system at zero cost.
- Selecting TRUST on a false report: System decays further; extra resource penalty is applied.
- Selecting VERIFY: Deducts audit resource cost, displays raw substrate readings, and safely calibrates the system.
```

## Provenance

```pbc:provenance
- ref: bulkhead-voyage/index.html
  confidence: verified
  note: Audit decision and trust-vs-verify logic.
- ref: bulkhead-messenger/index.html
  confidence: verified
  note: 2D avatar canvas and walkable map.
- ref: bulkhead-voyage-messenger/index.html
  confidence: verified
  note: Implements the synthesized exploration-audit gameplay.
```
