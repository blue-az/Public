# Codex vs Claude Code Is a False Choice

*A domain-building case study in comparing implementation paths, not models in the abstract.*

## Status

Frozen / Published, Paper 1.38. Authored 2026-06-01, registered 2026-06-08,
and frozen 2026-06-08. Promoted from `ready_to_draft` on the basis of:

- The artifact-backed side-by-side inventory at
  `docs/domain_runs/AMKOR-CASE-001/side_by_side_inventory.md`, whose load-bearing
  claims were re-verified against the on-disk domains on 2026-06-01.
- The two formal Domain Build Benchmark supervisor verdicts the case study sits
  beside: `docs/domain_runs/DBB-001/codex_frontier/supervisor_verdict.md`
  (`PASS_WITH_WAIVER`) and `docs/domain_runs/DBB-001a/claude_frontier/supervisor_verdict.md`
  (`PASS`, "cleanest run in the DBB-001 group so far").
- The archived operator-supplied source at
  `docs/domain_runs/AMKOR-CASE-001/linkedin_post_archive.md`, retained as
  anecdotal context, explicitly **not** as an independent benchmark result.

This paper is registered in `docs/PAPERS_MANIFEST.json` and published through
the Bulkhead Tau paper index.

## Thesis

"Claude Code vs Codex" is a real comparison and an almost-always false choice.
The two tools are not locked in: an operator can use either, switch between
them, or use both, so the abstract question *which model is better* rarely pays
rent. The question that does pay rent is narrower and answerable from artifacts:

> Under a shared scaffold, a shared validator discipline, and the same operator
> review, **which implementation path produced the better rough domain — and
> which surface did each path win?**

In the Amkor / xAmkor case, the answer is not winner-take-all. The Codex-authored
domain was more *operationally complete* at handoff — its verifier surface was
executable, tested, and reproducibility-oriented. The Claude-authored domain was
more *ambitious as an application* — it carried a richer cockpit core and broader
schema/feature scaffolding. The strongest path is therefore **compositional**:
the Codex-style verifier discipline plus the Claude-style cockpit/application
surface. The choice between models is a false binary; the useful act is choosing
which *surface* each path is trusted to own.

This is an engineering-process claim, not a model leaderboard.

## The Case

The task was identical for both agents: build a tau-bench-style Project Phoenix
domain on publicly available data (Amkor Technology, a semiconductor packaging
firm) under Project Phoenix principles — a versioned variation ladder, a SQLite
data substrate built from public SEC / market / news / jobs sources, and an SOP
that drives Policy → Tools → Tasks.

- `Amkor` — authored by Claude Code (`domains/ExperimentalAgents/Amkor`)
- `xAmkor` — authored by Codex (`domains/ExperimentalAgents/xAmkor`)

Both domains exist on disk today with a shared baseline: `schema.sql`,
`service.py`, `scripts/init_db.py`, the same family of SEC/companyfacts/filings/
jobs/news/prices pull scripts, a `variations/variation_1` through `variation_4`
ladder, and a built SQLite artifact. That shared baseline is what makes the
comparison fair: the divergence is in what each agent did *above* the scaffold,
not in whether they had the same starting line.

## Two Layers of Evidence, Held Apart on Purpose

This paper deliberately separates a weak evidence layer from a strong one, and
rests its claim only on the strong layer.

### Layer 1 — the reported ratings (anecdotal)

The operator asked each agent to rate both domains. As reported in the public
post:

| Judge | Amkor | xAmkor | Reported judgment |
|---|---:|---:|---|
| Claude Code | 6.5/10 | 8.0/10 | xAmkor wins on engineering correctness; Amkor wins on feature surface. |
| Codex | 6.5/10 | 8.8/10 | xAmkor is more operational and validator-friendly today. |

Both judges converged on the same direction: Codex produced the more complete
rough draft. That convergence is suggestive — but these are agent self/peer
assessments recounted in a LinkedIn post, not independent benchmark scores, and
the original rating prompts and transcripts were not recovered. **The ratings
are treated here as anecdote, not as a result.** They motivate the question;
they do not answer it.

### Layer 2 — the artifact inventory (load-bearing)

The answerable version of the question is settled by reading the two domains as
they sit in the repository. Each axis below was verified against the files on
2026-06-01.

| Axis | Amkor (Claude Code) | xAmkor (Codex) | Artifact-backed read |
|---|---|---|---|
| Schema | Core company-performance tables plus `hypothesis_scores`, `text_disclosures`, `target_roles`, `role_requirements` | Core tables: metrics, prices, filings, jobs, news, events | Amkor has the broader schema surface |
| V4 tools | `variation_4/tools.py` is a 37-line placeholder registry; its own docstring says executable wiring "belongs in `cockpit_poc/agent/core/tool_registry.py`" | `variation_4/tools.py` is a 781-line module with real `Tool` subclasses (`EvaluateVariation4Readiness`, `SubmitAdvisoryHypothesisScore`, `BuildVisualizationPack`, …) | xAmkor has the executable benchmark-style V4 |
| SOP / docs | `README.md`, `CLAUDE.md` | `README.md`, `CLAUDE.md`, plus `PP_REMEDIATION_CHECKLIST.md` | xAmkor adds an explicit remediation/proof checklist |
| Validation | Cockpit test suite under `cockpit_poc/agent/tests/test_agent.py`; no domain-level repro smoke at root | `tests/test_variation4_hitl.py` + `scripts/repro_smoke.py` | xAmkor has the clearer domain-build validation surface for handoff |
| HITL / cockpit | Rich cockpit core under `cockpit_poc/agent/core/` (agentic engine, data client, plan builder, tool registry, execution context, visualization pack) | No `cockpit_poc/` at all; HITL is implemented inside the V4 tools and tests — GO/NO_GO gating, write-then-verify score writes, template-only claims | Amkor has cockpit/application depth; xAmkor has tighter, verifiable HITL controls |
| Public visualization | `https://proto.efehnconsulting.com/amkor/` | `https://proto.efehnconsulting.com/xamkor/` | Both have recorded public surfaces |

The single sharpest number is the V4 implementation gap: **37 lines of
placeholder versus 781 lines of executable, tested tool code.** The Codex path
shipped a working verifier surface; the Claude path deferred its V4 wiring to a
cockpit layer it had also built but not connected to the variation ladder.

The asymmetry runs both ways and that is the point. Reading only xAmkor, you
would conclude Codex builds more complete domains. Reading only Amkor, you would
conclude Claude Code builds more ambitious systems. Reading them side by side,
the honest conclusion is that each agent optimized a different surface, and the
operator's job is to know which surface to take from which path.

## Proof Boundary

This is stated explicitly because the case study is easy to over-sell:

- The auditable claim is limited to repository artifacts at the recorded paths.
- The reported ratings are anecdotal source context, not benchmark scores.
- Original rating prompts/transcripts were not recovered; if they ever are, they
  belong in an appendix as a rating-prompt matrix, not as load-bearing evidence.
- This compares two specific domains built once each. It is a case study, not a
  controlled multi-trial benchmark, and it does not generalize to "Codex builds
  better domains than Claude Code." It supports the narrower, surface-specific
  reading above.

## Relation to the Formal Domain Build Benchmark

The case study sits next to the formal Domain Build Benchmark (DBB) records
rather than replacing them, and the two tell a consistent story.

- **DBB-001 / codex_frontier** — `final_verdict: PASS_WITH_WAIVER`. First-pass
  structural validity and final validator-backed quality both pass; the waiver
  reflects process caveats noted in the first row. A lower-friction
  implementation path with a clean substantive baseline.
- **DBB-001a / claude_frontier** — `final_verdict: PASS`, characterized by the
  supervisor as the "cleanest run in the DBB-001 group so far," after the
  benchmark protocol had been hardened.

The DBB rows sharpen the same distinction the Amkor/xAmkor artifacts show: the
Codex path tends to reach a validator-friendly baseline with low friction; the
Claude path produces clean, procedure-aware work, particularly once the
surrounding discipline is in place. Neither verdict crowns a model. Both reward
the path that respected the validator boundary.

## Why "False Choice" Is the Right Frame

The lock-in story is the giveaway. Because there is no real switching cost
between these tools, "which is better" is rarely the decision an operator
actually faces. The decision is *composition*: which path owns the verifier
surface, which owns the cockpit/application surface, and how the operator merges
them under one review discipline. In the operator's own original words, the
ideal domain merges xAmkor's V4 implementation and HITL rigor with Amkor's
cockpit layer and 10-K text extraction. The artifacts make that merge concrete
rather than aspirational: both halves already exist, in two different
repositories, authored by two different agents.

The portable lesson for Project Phoenix domain building: **compare
implementation paths under evidence discipline, not models in the abstract.** The
scaffold, the validator, and the operator review are the constants; the agent is
a swappable producer of a rough draft whose surfaces you then audit and combine.

## What This Paper Is Not

- It is not a claim that one model is generally superior.
- It is not a benchmark; N = 1 domain per path, built once.
- It does not rehabilitate the reported ratings into scores.
- It does not measure cost, latency, or token usage of the two build sessions —
  that lane belongs to the cost papers, not here.

## Reproduction

```bash
# Shared baseline and per-domain divergence
find domains/ExperimentalAgents/Amkor domains/ExperimentalAgents/xAmkor -maxdepth 2 -type f | sort

# The load-bearing V4 implementation gap (37 lines vs 781 lines)
wc -l domains/ExperimentalAgents/Amkor/variations/variation_4/tools.py \
      domains/ExperimentalAgents/xAmkor/variations/variation_4/tools.py

# Amkor has a cockpit core; xAmkor does not
ls domains/ExperimentalAgents/Amkor/cockpit_poc/agent/core/
ls -d domains/ExperimentalAgents/xAmkor/cockpit_poc 2>&1   # No such file or directory

# xAmkor's verifier surface
ls domains/ExperimentalAgents/xAmkor/tests/test_variation4_hitl.py \
   domains/ExperimentalAgents/xAmkor/scripts/repro_smoke.py

# Evidence packet and formal DBB verdicts
cat docs/domain_runs/AMKOR-CASE-001/side_by_side_inventory.md
cat docs/domain_runs/DBB-001/codex_frontier/supervisor_verdict.md
cat docs/domain_runs/DBB-001a/claude_frontier/supervisor_verdict.md
```

## Provenance

Drafted by Claude Code (session 2026-06-01) from the artifact-backed evidence
packet `AMKOR-CASE-001`, the two DBB-001 supervisor verdicts, and the on-disk
Amkor/xAmkor domains. The promotion gate for this paper line
(`DOMAIN-BUILD-INVENTORY-001` in `docs/PAPER_STUB_PLAN.yaml`) was satisfied by
the side-by-side inventory rather than by recovering the original rating
transcripts. The original lineage stub was retired at freeze. No domain code
was modified in the course of drafting.
