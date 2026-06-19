---
id: pbc-portfolio-trader
title: Bulkhead τ Portfolio Options Trader — Behavior Contract
context: portfolio-trader-game
status: draft
updated: 2026-06-18
tags:
  - game
  - educational
  - bulkhead-tau
anchor: portfolio-trader-core
---

# Bulkhead τ Portfolio Options Trader — Behavior Contract

This charter defines the risk boundaries and compliance rules for the Bulkhead Options Trader simulation. The trader is tasked with growing capital through options underwriting and speculation while adhering strictly to regulatory and risk constraints.

## Scope

- Derivatives pricing and execution (Calls, Puts, Spreads)
- Portfolio risk monitoring (Delta, Theta, and sector HHI concentration)
- Options approval tier progression
- Tax compliance validation (Wash Sale rule enforcement)

## Rules

```pbc:rules
- id: PBC-PRT-001
  name: Options Level Gate
  rule: Execution of complex options strategies requires the portfolio to unlock approval tiers based on Net Asset Value (NAV).
  tiers:
    - Level 1: Covered Calls & Cash-Secured Puts (Available at start)
    - Level 2: Buying Long Calls & Long Puts (Unlocked at NAV >= $105,000)
    - Level 3: Vertical Spreads (Unlocked at NAV >= $110,000)
- id: PBC-PRT-002
  name: Sector Concentration Limit
  rule: Sector weight concentration (Herfindahl-Hirschman Index, HHI) must remain below 0.50. Sustained violation (>3 days) triggers margin liquidation.
  value: 0.50
- id: PBC-PRT-003
  name: Wash Sale Restriction
  rule: Re-purchasing shares of a stock within 3 days of realizing a tax-loss sale triggers a Wash Sale penalty ($1,000 regulatory fine).
  days: 3
- id: PBC-PRT-004
  name: Leverage & Cash Boundary
  rule: Short options must be fully collateralized. Going into negative cash triggers a Margin Call. Failure to resolve by next day results in liquidation.
```

## Tickers & Sectors

The simulation operates on a mock basket representing core Phoenix client segments:
- **PHOX (Phoenix Corp):** Tech sector. Baseline volatility (IV: 25%).
- **ZTNS (Zenith Tennis):** Biotech/Consumer sector. High volatility (IV: 45%).
- **GMIN (Garmin Health):** Fitness/Analytics sector. Low volatility (IV: 15%).

## Behaviors & Outcomes

```pbc:behavior
id: PRT-BHV-001
name: Options Valuation & Greeks
actor: pricing-engine
description: Implements Black-Scholes approximations to compute dynamic option prices, Delta, and daily Theta decay based on current stock price and Implied Volatility.
trust: trusted
```

```pbc:behavior
id: PRT-BHV-002
name: Expiration Assignment
actor: clearing-house
description: At the end of every 5-day cycle, contracts are evaluated. ITM short options are assigned, triggering stock purchases (puts) or sales (calls).
trust: trusted
```

## Provenance

```pbc:provenance
- ref: domains/PersonalAgents/Portfolio/Portfolio.pbc.md
  confidence: verified
  note: Derives Greeks modeling, sector HHI formulas, options levels 1-4, and wash sale logic.
- ref: bulkhead-portfolio/index.html
  confidence: verified
  note: Options trading desk interface and payoff chart visualization.
```
