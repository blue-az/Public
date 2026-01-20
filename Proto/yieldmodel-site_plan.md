# YieldModel Site Plan

A website documenting the YieldModel domain - IC manufacturing yield analysis built on Project Phoenix.

---

## Site Purpose

Document the YieldModel agentic cockpit for PCB/IC manufacturing yield analysis, showcasing the physics-based optimization model and deterministic tool execution.

---

## Proposed URL

`https://proto.efehnconsulting.com/yield-model/`

---

## Domain Overview

| Attribute | Value |
|-----------|-------|
| **Version** | 4.1 |
| **Total Tools** | 18 (9 CLI + 13 Cockpit, with overlap) |
| **Variations** | 2 (Basic Queries + Physics Models) |
| **Data** | 30 PCB boards, 14 component types (A-N) |
| **Physics Model** | Y = ∏(1 - p_i)^n_i |

**Academic Reference:** Based on Felipe Helo's research: "Decision Support System to Predict the Manufacturing Yield of Printed Circuit Board Assembly Lines"

---

## Page Structure

### 1. index.html - Home / Overview

**Content:**
- Tagline: "IC Manufacturing Yield Analysis - Agentic Analyst's Cockpit"
- Domain description: PCB/IC yield prediction using physics-based models
- Key stats: 30 boards, 14 components, 18 tools
- Physics model formula with explanation
- State machine flow: IDLE → PLANNING → AWAITING_APPROVAL → RUNNING → COMPLETED
- Navigation to all sections

**Visual Elements:**
- Hero section with yield formula
- Dataset preview (sample board data)
- Quick start query examples

**Source:** `CLAUDE.md`, `IMPLEMENTATION_SUMMARY.md`

---

### 2. tools.html - Tool Catalog

**Content:**

#### Board Tools (Category: board)
| Tool | Description | Parameters |
|------|-------------|------------|
| `find_best_board` | Find highest-yield board | metric (yield/component), top_n |
| `find_worst_board` | Find lowest-yield board | bottom_n |
| `rank_boards` | Rank all boards by yield | limit |

#### Analysis Tools (Category: analysis)
| Tool | Description | Parameters |
|------|-------------|------------|
| `get_board_summary` | Comprehensive board details | board_id (required) |
| `analyze_component_impact` | Component-yield correlations | none |
| `compare_boards` | Compare multiple boards | board_ids (list, required) |
| `run_physics_model` | Physics-based optimization | max_fault_prob |
| `find_outliers` | Statistical outliers (>2 std) | threshold |
| `get_component_statistics` | Stats for component type | component (A-N, required) |
| `predict_yield` | Predict yield for config | components (object, required) |

#### Visualization Tools (Category: visualization)
| Tool | Description | Parameters |
|------|-------------|------------|
| `visualize_yield_distribution` | Yield histogram and stats | none |

#### Export Tools (Category: export)
| Tool | Description | Parameters |
|------|-------------|------------|
| `export_data` | Export to CSV/JSON | format, filename (required) |

#### Info Tools (Category: info)
| Tool | Description | Parameters |
|------|-------------|------------|
| `show_capabilities` | Display agent capabilities | none |

**Source:** `cockpit_poc/agent/tool_registry.py`

---

### 3. tasks.html - Natural Language Queries

**Content:**

#### Session Analysis
| Query | Plan Generated |
|-------|---------------|
| "analyze best board" | find_best_board → get_board_summary → analyze_component_impact → visualize_yield_distribution |
| "compare boards 5 and 12" | get_board_summary (x2) → compare_boards |
| "compare top 5 boards" | find_best_board → compare_boards |

#### Physics Analysis
| Query | Plan Generated |
|-------|---------------|
| "run physics model" | run_physics_model → analyze_component_impact |
| "analyze component impact" | analyze_component_impact |

#### Visualization
| Query | Plan Generated |
|-------|---------------|
| "show yield distribution" | visualize_yield_distribution |
| "histogram" | visualize_yield_distribution |

#### Board Queries
| Query | Plan Generated |
|-------|---------------|
| "show board 5 summary" | get_board_summary |
| "find top 10 boards" | find_best_board |

#### Export
| Query | Plan Generated |
|-------|---------------|
| "export data to csv" | export_data |

**Source:** `cockpit_poc/agent/plan_builder.py`

---

### 4. physics.html - Physics Model

**Content:**

#### The Yield Formula
```
Y = ∏(1 - p_i)^n_i
```
Where:
- Y = Overall board yield (probability of no defects)
- p_i = Fault probability for component type i
- n_i = Count of component type i on the board

#### SLSQP Optimization
- Uses scipy.optimize.minimize with SLSQP method
- Bounds: 0.0 to max_fault_prob (default 0.05) for each component
- Objective: Minimize squared error between predicted and observed yields

#### Model Comparison
- Physics model vs Linear Regression baseline
- RMSE and MAE metrics for comparison
- Most/least reliable component identification

#### Sample Results
- Best board: #11 (99.91% yield)
- Worst board: #23 (61.67% yield)
- Most reliable component: GD (0.0000% fault)
- Least reliable component: JD (0.4910% fault)

**Source:** `IMPLEMENTATION_SUMMARY.md`, `tool_registry.py` (run_physics_model)

---

### 5. data.html - Dataset

**Content:**

#### Board Data Structure
| Column | Description | Type |
|--------|-------------|------|
| Board | Board identifier (1-30) | int |
| A-N | Component counts (14 types) | int |
| Yield | Manufacturing yield percentage | float |

#### Component Types (14)
```
A, DIP, DIPD, Nsth, nshthd, nsmthd, J, G, Ct, Cb, SOTt, SOTb, GD, JD
```

#### Dataset Statistics
| Metric | Value |
|--------|-------|
| Total Boards | 30 |
| Component Types | 14 |
| Mean Yield | 89.07% |
| Median Yield | 90.95% |
| Std Dev | 10.34% |
| Best Yield | 99.91% (Board #11) |
| Worst Yield | 61.67% (Board #23) |

#### Sample Board Data
| Board | A | DIP | ... | Yield |
|-------|---|-----|-----|-------|
| 1 | 123 | 580 | ... | 86.32% |
| 2 | 323 | 240 | ... | 80.64% |
| 3 | 20 | 292 | ... | 84.10% |

**Source:** `data/board_yield_data.csv`

---

### 6. architecture.html - System Architecture

**Content:**

#### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────────────┐
│                    YIELD ANALYST'S COCKPIT                          │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  USER INTERFACE                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Command Input: [analyze best board              ] [Run]      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────┐  ┌────────────────────────────────────┐ │
│  │ BLUEPRINT PANEL       │  │ EXECUTION TRACE                    │ │
│  │ Step 1: find_best     │  │ [19:26:03] Parsing query...       │ │
│  │ Step 2: get_summary   │  │ [19:26:05] find_best_board()      │ │
│  │ Step 3: analyze       │  │ [19:26:05] Found: Board #11       │ │
│  │ [Approve] [Cancel]    │  │ [19:26:06] Completed in 1.8s      │ │
│  └──────────────────────┘  └────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  AGENTIC ENGINE                                                      │
│  State: IDLE → PLANNING → AWAITING_APPROVAL → RUNNING → COMPLETED   │
│                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐ │
│  │ PlanBuilder       │  │ ToolRegistry     │  │ ExecutionContext │ │
│  │ • Pattern match   │  │ • 13 tools       │  │ • Three-tier     │ │
│  │ • Entity extract  │  │ • Typed params   │  │   caching        │ │
│  │ • Build plan      │  │ • Execute fn     │  │ • Step results   │ │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  DATA LAYER (YieldDataClient)                                        │
│                                                                      │
│  ┌──────────────────────────────┐  ┌─────────────────────────────┐ │
│  │ board_yield_data.csv          │  │ fab_configs.json            │ │
│  │ (30 boards, 14 components)    │  │ (Semiconductor fab configs) │ │
│  └──────────────────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

#### Component Responsibilities
| Component | Location | Responsibility |
|-----------|----------|----------------|
| AgenticEngine | agentic_engine.py | State machine, plan execution |
| PlanBuilder | plan_builder.py | NL parsing, pattern matching |
| ToolRegistry | tool_registry.py | 13 tool registrations, execution |
| ExecutionContext | execution_context.py | Three-tier caching |
| YieldDataClient | data_client.py | CSV loading, DataFrame ops |

**Source:** `CLAUDE.md` architecture section

---

### 7. rules.html - Domain Rules

**Content:**

#### Data Integrity Rules
| Rule | Description |
|------|-------------|
| R1 | No yield fabrication - all values from board_yield_data.csv |
| R2 | Board IDs are 1-indexed integers (1-30) |
| R3 | Component types are uppercase letters (A-N) |

#### Query Processing Rules
| Rule | Description |
|------|-------------|
| R4 | Deterministic results - same query = same output |
| R5 | Board ID validation before lookup |
| R6 | Default top_n = 1 for find_best_board |

#### Physics Model Rules
| Rule | Description |
|------|-------------|
| R7 | Fault probabilities bounded [0.0, max_fault_prob] |
| R8 | Default max_fault_prob = 0.05 (5%) |
| R9 | SLSQP optimization with RMSE objective |

#### Caching Rules
| Rule | Description |
|------|-------------|
| R10 | Board summaries cached by board_id |
| R11 | Physics results cached by max_fault_prob |
| R12 | Component stats cached by component letter |

**Source:** Derived from `tool_registry.py` behavior

---

### 8. principles.html - Tau-Bench Implementation

**Content:**

#### Pass^k Reliability
- Deterministic queries: "find best board" returns Board #11 every time
- No randomness in optimization (deterministic SLSQP)
- Cached results ensure consistency

#### Domain Policy Following
- 12 rules governing data integrity, query processing, physics constraints
- Component validation (A-N only)
- Board ID validation (1-30 only)

#### Structured Tool Use
- 13 tools with typed parameters
- Parameter validation before execution
- JSON-serializable returns

#### Four-Phase Implementation
- Phase 1 (Glass Box): Blueprint Panel shows plan before execution
- Phase 2 (Human-in-the-Loop): Approve/Cancel before running
- Phase 3 (Progressive Disclosure): Drill into results
- Phase 4 (Multi-Modal Output): Matplotlib visualizations

**Source:** `CLAUDE.md`, `PROJECT_PHOENIX_OVERVIEW.md`

---

## Navigation Structure

```
[Home] [Tools] [Tasks] [Physics] [Data] [Architecture] [Rules] [Tau-Bench]
```

---

## Design Notes

### Visual Style
- Industrial/manufacturing aesthetic
- Dark theme with accent colors for components
- Data tables for board/component information
- ASCII diagrams for architecture (consistent with TennisAgent)

### Key Visual Elements
- Physics formula prominently displayed
- Yield distribution histogram mockup
- Component impact correlation chart
- Board ranking table

### Color Scheme Suggestion
- Primary: Steel blue (#4682B4)
- Accent: Industrial orange (#FF6600)
- Background: Dark (#1a1a1a)
- Text: Light gray (#e0e0e0)

### Footer
```
YieldModel - IC Manufacturing Yield Analysis
Built on Project Phoenix / tau-bench (MIT)
```

---

## Source Files Reference

| File | Location | Content |
|------|----------|---------|
| CLAUDE.md | `/home/blueaz/Python/project-phoenix/domains/YieldModel/` | Overview, commands |
| IMPLEMENTATION_SUMMARY.md | Same | Detailed implementation docs |
| tool_registry.py | `cockpit_poc/agent/` | 13 tool definitions |
| plan_builder.py | `cockpit_poc/agent/` | Query patterns |
| board_yield_data.csv | `data/` | 30 boards, 14 components |

---

## Implementation Order

1. Create `yield-model/` directory
2. Generate `index.html` with physics formula and overview
3. Generate `tools.html` with 13 cockpit tools
4. Generate `tasks.html` with query patterns
5. Generate `physics.html` with model explanation
6. Generate `data.html` with dataset details
7. Generate `architecture.html` with system diagrams
8. Generate `rules.html` with domain policies
9. Generate `principles.html` with tau-bench implementation
10. Create `style.css` (industrial theme)
11. Deploy and verify

---

## Link to Project Phoenix

Add to domains page on project-phoenix site:

| Domain | Tools | Version | Focus | Website |
|--------|-------|---------|-------|---------|
| YieldModel | 18 | 4.1 | IC manufacturing yield | [View Site](https://proto.efehnconsulting.com/yield-model/) |

---

## Validation Checklist

- [ ] All 13 cockpit tools listed correctly
- [ ] Physics formula matches implementation
- [ ] Dataset stats match board_yield_data.csv
- [ ] Query patterns match plan_builder.py
- [ ] Architecture matches CLAUDE.md
- [ ] No fabricated results or features
