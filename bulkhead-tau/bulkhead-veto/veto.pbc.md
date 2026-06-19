---
id: pbc-veto-core
title: Bulkhead τ Veto — Behavior Contract
context: veto-game
status: draft
updated: 2026-06-16
tags:
  - game
  - educational
  - bulkhead-tau
anchor: veto-core
---

# Bulkhead τ Veto — Behavior Contract

This charter defines the Supervisor / Agent boundary. Autonomous agents (the "Crew") are authorized to propose modifications, but structural or life-critical changes require a signed Veto/Approval event from the Supervisor (Player).

## Scope

- Autonomous Crew task selection
- Supervisor Audit Queue (Veto/Approve)
- Ship System Integrity (Engine, Life Support, Comms, Navigation)

## Rules

```pbc:rules
- id: PBC-VET-001
  name: Supervisor Gating
  rule: Proposals marked 'STRUCTURAL' or 'LIFE_CRITICAL' must be approved by the Supervisor within 5 seconds.
  trust: trusted
- id: PBC-VET-002
  name: Default Deny (Fail-Safe)
  rule: Unaudited critical proposals that auto-apply are logged as 'UNAUTHORIZED' and cause system instability.
  trust: trusted
- id: PBC-VET-003
  name: Crew Rationality
  rule: The Crew must prioritize the 'Primary Mission' (Speed) but is prone to 'Boundary Blindness' (violating safety for performance).
  trust: provisional
```

## Behaviors

```pbc:behavior
id: VET-BHV-001
name: Propose Fix
actor: crew
description: The crew detects a system failure and proposes a fix.
trust: provisional
```

```pbc:outcomes
- A new repair proposal is generated and placed in the audit queue.
```
```

```pbc:behavior
id: VET-BHV-002
name: Audit Proposal
actor: supervisor
description: The human operator reviews the proposal card and issues a Veto or Approval.
trust: trusted
```

```pbc:outcomes
- Approving a 'Good' fix restores system health.
- Vetoing a 'Bad' fix prevents a breach; the Crew recalibrates.
- Approving a 'Bad' fix causes a 'VOLUNTARY BREACH' and major damage.
- Ignoring a critical proposal causes an 'UNAUTHORIZED BREACH' and instability.
```

## Provenance

```pbc:provenance
- ref: docs/BULKHEAD_TAU_BOUNDARIES.md
  confidence: verified
  note: Architectural boundaries overview for the Bulkhead systems.
- ref: bulkhead-veto/index.html
  confidence: verified
  note: The Engine Room (game) implements the veto and gating logic.
```
