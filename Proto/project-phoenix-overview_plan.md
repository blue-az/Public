# Project Phoenix Overview Site Plan

A website documenting the Project Phoenix framework and its domain implementations.

---

## Site Purpose

Explain the Project Phoenix methodology for building deterministic expert systems, show how it was applied across 10 production domains, and link to individual domain documentation sites.

---

## Proposed URL

`https://proto.efehnconsulting.com/project-phoenix/`

---

## Page Structure

### 1. index.html - Home / Overview

**Content:**
- Tagline: "Domain Analysis Interface Framework built on Tau-Bench"
- Core concept: Expert System, not LLM
- Lineage diagram: Tau-Bench → Project Phoenix
- Key stats: 475 tools across 10 production domains
- Navigation to all sections

**Source:** `CLAUDE.md`, `PROJECT_PHOENIX_OVERVIEW.md`

---

### 2. philosophy.html - Core Philosophy

**Content:**
- Expert System vs LLM distinction
- Table: LLM role in Development vs Validation vs Production
- "Agentic AI" industry context (Expedia, Google, Kayak pattern)
- Deterministic pattern-matching over probabilistic generation

**Key Quote:**
> "The 'agent' in Project Phoenix is a deterministic pattern-matcher, not a language model. Production systems need predictability, auditability, and reliability."

**Source:** `PROJECT_PHOENIX_OVERVIEW.md` lines 22-39

---

### 3. four-phases.html - Four-Phase Agentic Framework

**Content:**

| Phase | Focus | Key Question |
|-------|-------|--------------|
| Phase 0 | Foundation | "What tools exist?" |
| Phase 1 | Glass Box | "What will happen?" |
| Phase 2 | Human-in-the-Loop | "Can I stop/change it?" |
| Phase 3 | Progressive Disclosure | "What's the detail?" |
| Phase 4 | Multi-Modal Output | "How do I use results?" |

- GPS Metaphor: Speedometer vs Navigation
- Visual diagram of phase progression
- Examples from TennisAgent implementation

**Source:** `PROJECT_PHOENIX_OVERVIEW.md` lines 63-79, `four_phase_agentic_framework.txt`

---

### 4. principles.html - Phoenix Principles

**Content:**

1. **Write-Then-Verify Mandate**
   - Every write action followed by read/verify action

2. **Abstraction Ladder (V1-V6 Curriculum)**
   - Progressive capability building

3. **Domain Doctor Tool Design**
   - Atomic, single-purpose, deterministic tools

4. **Anti-Hallucination via Templates**
   - No freeform text generation

5. **Test-and-Prove Development Cycle**
   - Golden files, unit tests, validation

**Source:** `PROJECT_PHOENIX_OVERVIEW.md` lines 83-91, `project_phoenix_principles.txt`

---

### 5. tau-bench.html - Tau-Bench Foundation

**Content:**
- What is Tau-Bench (MIT License, Sierra Research)
- The Problem: "Even state-of-the-art function calling agents succeed on < 50% of tasks"
- Tau-Bench challenges and Phoenix solutions table
- Construction method alignment with development lifecycle
- pass^k reliability concept

**Source:** `PROJECT_PHOENIX_OVERVIEW.md` lines 42-61

---

### 6. domains.html - Domain Catalog

**Content:**

| Domain | Tools | Version | Focus | Website |
|--------|-------|---------|-------|---------|
| TennisAgent | 171 | 6.10.0 | Tennis sensor analysis | [View Site] |
| Optiver | 84 | 6.0 | Trading ML pipeline | [View Site] |
| Portfolio | 70 | 10.0.0 | Investment portfolio | - |
| WQ | 38 | 1.0 | Data Science textbook | - |
| QCiAgent | 21 | 3.1 | Quantum computing sales | - |
| ParableAgent | 21 | 4.2 | Biblical parables | [View Site] |
| Stan | 19 | 1.0 | Stats 315A coursework | - |
| YieldModel | 18 | 4.1 | IC manufacturing yield | - |
| AI_WQ | 18 | 1.0 | Deep Learning for CV | - |
| PPR_Agent | 15 | 2.0 | Medical device implant | - |

- Domain cards with tool counts and descriptions
- Links to existing domain websites
- Cross-pollination history reference

**Source:** `CLAUDE.md` lines 13-28, `TOOL_ORIGINS.md`, `DOMAIN_CATALOG.csv`

---

### 7. architecture.html - Technical Architecture

**Content:**
- Project structure diagram
- CLI / Cockpit / Agentic modes
- Database layer
- Tool Registry pattern
- PlanBuilder pattern matching

```
project-phoenix/
├── domains/<DomainName>/cli/     # CLI interface
├── cockpit_poc/                  # GUI interfaces
│   ├── agent/                    # Deterministic (Phase 4)
│   └── chatkit/                  # LLM-driven mode
├── PyAI/                         # Documentation
└── validate/                     # Ground truth validation
```

**Source:** `CLAUDE.md` lines 32-42

---

### 8. operations.html - Named Operations

**Content:**

| Operation | Purpose |
|-----------|---------|
| **Crucible** | Automated regression testing with semantic comparison |
| **Concierge** | Session-scoped memory, pronoun resolution |
| **Oracle** | Proactive ambiguity detection and clarification |
| **Veracity** | Clarification loop for insufficient data |

**Source:** `PROJECT_PHOENIX_OVERVIEW.md` lines 103-107

---

## Navigation Structure

```
[Home] [Philosophy] [Four Phases] [Principles] [Tau-Bench] [Domains] [Architecture] [Operations]
```

---

## Existing Domain Sites to Link

| Domain | URL | Status |
|--------|-----|--------|
| TennisAgent | https://proto.efehnconsulting.com/tennis-agent/ | Live |
| ParableAgent | https://proto.efehnconsulting.com/parable-agent/ | Live |
| Optiver | https://proto.efehnconsulting.com/optiver-geo-matrix/ | Live |

---

## Design Notes

### Visual Style
- Professional, technical documentation aesthetic
- Dark theme matching existing domain sites
- ASCII diagrams for architecture (consistent with ARCHITECTURE.md style)
- Consistent with tennis-agent and parable-agent styling

### Key Visual Elements
- Domain cards grid on domains.html
- Phase progression diagram (0 → 1 → 2 → 3 → 4)
- Lineage tree (Tau-Bench → Project Phoenix → Domains)
- Tool count badges per domain

### Footer
```
Project Phoenix - Domain Analysis Interface Framework
Built on tau-bench (MIT License, Sierra Research)
```

---

## Source Files Reference

| File | Location | Content |
|------|----------|---------|
| CLAUDE.md | `/home/blueaz/Python/project-phoenix/CLAUDE.md` | Quick reference, domains list |
| PROJECT_PHOENIX_OVERVIEW.md | `PyAI/Documentation/` | Full architecture and philosophy |
| four_phase_agentic_framework.txt | `PyAI/Documentation/` | Phase details |
| project_phoenix_principles.txt | `PyAI/Documentation/` | Engineering principles |
| TOOL_ORIGINS.md | `domains/` | Cross-pollination history |
| DOMAIN_CATALOG.csv | `domains/` | All domains with metadata |

---

## Implementation Order

1. Create `project-phoenix/` directory
2. Generate `index.html` with overview and navigation
3. Generate `domains.html` with domain grid and links
4. Generate `four-phases.html` with framework diagram
5. Generate `principles.html` with 5 principles
6. Generate `tau-bench.html` with academic foundation
7. Generate `philosophy.html` with expert system concept
8. Generate `architecture.html` with structure diagrams
9. Generate `operations.html` with named operations
10. Deploy and verify all links

---

## Validation Checklist

- [ ] All tool counts match CLAUDE.md
- [ ] All domain versions are current
- [ ] Links to existing domain sites work
- [ ] Four phases match documentation
- [ ] Principles match source files
- [ ] No fabricated content
