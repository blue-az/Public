---
id: pbc-ppr-agent-domain
title: PPR_Agent — Parent System Charter
context: ppr-agent-domain
status: agreed
updated: 2026-06-09
tags:
  - demo
  - parent-charter
  - crm-device-analysis
  - product-performance
---

# PPR_Agent — Parent System Charter

The PPR_Agent domain provides an automated agentic cockpit and tool variations (v1–v4) for extracting, analyzing, and querying Cardiac Rhythm Management (CRM) device product performance reports. It tracks registered US implants, category shares, company portfolios, and competitive positioning across Abbott, Boston Scientific, and Medtronic datasets from 2008 to 2025.

## Scope

- Parsing natural language queries (top devices, market share trends, YoY growth, competitive positioning) into structured execution plans.
- Storing and querying 3,576 device models representing 92 million US implants in the SQLite database `ppr_agent.db`.
- Mapping device categories: Pacemaker, ICD, CRT-D, CRT-P, S-ICD, Leadless Pacemaker, and TPS.
- Normalizing company codes to standard tags: `ABT` (Abbott), `BSX` (Boston Scientific), and `MDT` (Medtronic).
- Implementing competitive intelligence metrics including Herfindahl-Hirschman Index (HHI) for market concentration.

## Non-goals

- Real-time clinical device monitoring or programming (analytical exploration of historical report datasets only).
- Directly parsing PDFs in the main query loop (PDF parsing is an offline ingestion task handled by extract_pdfs.py).

## Terms

| Term | Definition |
| --- | --- |
| CRM Device | Cardiac Rhythm Management device (pacemakers, ICDs, leads, etc.). |
| Registered Implants | Cumulative number of devices of a specific model registered as implanted in the US. |
| PPR Report | Product Performance Report published periodically by manufacturers to track reliability and implant statistics. |

```pbc:glossary
- term: CRM Device
  definition: Cardiac Rhythm Management device (pacemakers, ICDs, leads, etc.).
- term: Registered Implants
  definition: Cumulative number of devices of a specific model registered as implanted in the US.
- term: PPR Report
  definition: Product Performance Report published periodically by manufacturers to track reliability and implant statistics.
```

## Actors

```pbc:actors
- id: plan_builder
  name: NLP Plan Builder
  type: system
  description: Regexp parser mapping operator CRM queries to tool step sequences.
- id: agentic_engine
  name: Agentic Engine
  type: system
  description: Multi-step orchestrator stepping through CRM tools and updating context.
- id: ppr_data_client
  name: PPR Data Client
  type: system
  description: SQLite database connector querying the devices data tables.
```

## States

```pbc:states
- id: idle
  definition: Cockpit is active and waiting for a CRM query.
  user_access: all
- id: planning
  definition: Translating NL query to tools and parameters.
  user_access: none
- id: awaiting_approval
  definition: Awaiting consent to execute the plan.
  user_access: all
- id: running
  definition: Executing database queries and calculating market metrics.
  user_access: none
- id: completed
  definition: Showing device lists, category breakdowns, and growth leaderboards.
  user_access: all
```

## Rules

```pbc:rules
- id: PPR-RUL-001
  name: Pattern Matching Precedence
  rule: Specific comparative queries (compare Abbott and Medtronic ICDs) must be matched before generic top device listings to avoid false plan generation.
  trust: trusted
- id: PPR-RUL-002
  name: Company Code Normalization
  rule: All queries targeting manufacturers must be normalized to standard codes ('ABT', 'BSX', 'MDT') before hitting the database.
  trust: trusted
- id: PPR-RUL-003
  name: Year Boundary Verification
  rule: Queries containing years outside the 2008-2025 range must either return a warning or cap range limits to valid bounds.
  trust: trusted
```

## Behaviors

```pbc:behavior
id: PPR-BHV-001
name: Compile plan
actor: plan_builder
description: Converts user input string into ExecutionPlan steps.
trust: trusted
```

```pbc:preconditions
- Input query is a non-empty string.
```

```pbc:trigger
- Operator enters query in cockpit.
```

```pbc:outcomes
- ExecutionPlan steps compiled.
```

```pbc:behavior
id: PPR-BHV-002
name: Get Market Concentration
actor: agentic_engine
description: Computes Herfindahl-Hirschman Index (HHI) for CRM market concentration.
trust: trusted
```

```pbc:preconditions
- Target year is within valid bounds.
```

```pbc:trigger
- Orchestrator triggers get_market_concentration.
```

```pbc:outcomes
- Returns HHI value and market concentration rating.
```

## Transitions

```pbc:transitions
- from: idle
  to: planning
  condition: Query submitted by user.
- from: planning
  to: awaiting_approval
  condition: Plan builder successfully resolves intents.
- from: awaiting_approval
  to: running
  condition: Operator approves plan.
- from: running
  to: completed
  condition: SQLite database query finishes.
- from: completed
  to: idle
  condition: Workspace reset.
```

## Provenance

```pbc:provenance
- ref: domains/DemoAgents/PPR_Agent/CLAUDE.md
  confidence: verified
  note: Documenting the 15 tools, SQLite schema, and company/category codes.
- ref: domains/DemoAgents/PPR_Agent/cockpit_poc/agent/core/data_client.py
  confidence: verified
  note: Database access layer querying ppr_agent.db tables.
- ref: domains/DemoAgents/PPR_Agent/cockpit_poc/agent/core/plan_builder.py
  confidence: verified
  note: Regexp pattern matching prioritizing competitive comparisons.
```

