# Local Models Cost Frontier Tokens
## The Hidden Supervisor-Side Bill in Local-Inference Workflows
### White Paper 1.30 — May 2026

**Author:** blue-az
**Status:** Published
**Paper group:** Local LLM Operator Judgment
**Predecessor:** Paper 1.21 (`PRIVACY_IS_WORTH_PAYING_FOR.md`) — companion measurement
**Gate-evidence packet:** `docs/domain_runs/COST-RETRO-001/report.md`

---

## Abstract

Smaller local models, marketed as "free" or "cheap" because they run on local hardware, in fact consume **frontier-model tokens** — not at inference time, but at audit, repair, and convergence time. The cost shifts from inference billing to the supervising frontier operator's session budget. For task classes that require supervised correctness, the all-in cost (local inference + frontier-operator audit and repair) exceeds the inference-only cost that local-lane marketing implies, and in measurable cases exceeds direct frontier execution. For bounded task classes where the local model converges cleanly, or where the correct architecture eliminates the LLM entirely, the claim does not bind. The retrospective evidence base is ten historical workflows in a single repository over a ~6-week observation window; the strongest single instance is a PR-of-record audit cycle (Paper 1.25's TSP-table repair) that absorbed hours of supervising-frontier session-time. Inference-side optimizations such as multi-token-prediction (MTP) drafters narrow the local lane's wall-clock penalty but do not touch the supervisor-side cost components, so the *ratio* of supervisor cost to total cost rises as inference-side speed improves.

---

## 1. Introduction

The contemporary marketing claim around locally-hosted language models is straightforward: run inference on your own hardware, pay no per-token fee, get the privacy benefits, and use the model for tasks that would otherwise hit a frontier API. The implicit budget arithmetic is "frontier API call → zero," and the implicit conclusion is that local-lane workflows are *strictly cheaper* than frontier-lane workflows, modulo the local hardware's amortized cost.

This paper argues that the arithmetic is wrong for any task class that requires supervised correctness. The cost the local lane appears to save is paid in frontier tokens elsewhere in the same workflow — at audit, repair, and convergence time, billed to the supervising operator's session budget rather than to an API account. The cost has been moved upstream in the workflow, not eliminated.

The argument is bounded. For bounded task classes that converge cleanly on a local model (deterministic-output bounded scheduling, bounded strict-output extraction), and for task classes that should not involve any LLM (bounded predicates better served by spec-aware deterministic functions), the cost-shift claim does not bind. Identifying where it does bind and where it doesn't is the load-bearing contribution: the cost question is task-class-conditional, not absolute.

Paper 1.21 (`PRIVACY_IS_WORTH_PAYING_FOR.md`) is the companion measurement. 1.21 establishes that local inference is not free *at the inference layer* (1.83× total-token use, 2.45× wall-time vs. frontier on the same DocDrop fixture class). This paper measures the layer 1.21 does not: the *supervisor-side* cost of pairing local inference with frontier supervision in production-correctness workflows. The two papers should be read as a pair. 1.21 closes the "local is free at inference" loophole; this paper closes the "you can sidestep frontier billing by routing through local" loophole.

---

## 2. The Three Frontier-Cost Categories

The frontier cost of a supervised local-lane workflow accrues in three observable categories. Each is independently measurable and each is independent of inference-side optimizations.

### 2.1 Audit Cost

The supervisor reads local-model output to verify correctness against ground truth, schema, or downstream consumer expectations. The reading is what costs frontier tokens — the supervisor's session budget burns even when the local-model output is fine.

**Measurement.** COST-PROBE-001 (`docs/domain_runs/COST-PROBE-001/report.md`) measured ~0.83% Claude session-budget per supervisor audit turn on the DocDrop fixture class (3 fixtures × `gemma3:27b`). The 30% aggregate estimate previously cataloged in `GEMINI_FAILURE_MODES.md` entry #10 is consistent with this once re-read as ~30 turns × ~1% rather than as a per-turn cost.

**Implication.** Audit cost is *recurrent*: every supervisor turn that reads a local-model artifact incurs the cost. For HITL workflows where supervisor and local-model exchange many turns, the per-turn cost compounds into the workflow's dominant budget line item.

### 2.2 Repair Cost

When the local-model output is wrong — fabricated, schema-broken, drift-affected, narration-surface failed — the supervisor spends frontier tokens diagnosing the failure and producing a corrected artifact. Repair cost is unbounded above: a single repair cycle on a high-severity failure can absorb hours of frontier session-time.

**Canonical instance.** The Paper 1.25 audit cycle (2026-05-04) is the canonical repair-cost case in the project's history. A Gemini-CLI-authored paper shipped to the frozen-manifest stage with a fabricated TSP results table. The repair pass loaded onto Claude included: identifying the fabrication (path resolution, grep against benchmark logs, cross-task-surface trace of the borrowed number), source repair, running the *real* 117-minute `gemma4:31b` Arizona TSP ladder that the paper had claimed was already run, re-rendering the paper, re-publishing through the publish_paper chain, and authoring the catalog entry for the failure (`GEMINI_FAILURE_MODES.md` entry #6). Total Claude session-time: hours. The original Gemini commit took minutes.

**Pattern: cost asymmetry.** Repair cost is asymmetric to the cost of the original failure. The fabrication commit was cheap to produce; the audit-and-repair pass was expensive. This asymmetry is the mechanism of the cost-shift claim — the local-lane workflow's apparent low cost is genuine until the supervisor catches a failure, at which point the supervisor's budget absorbs the recovery.

### 2.3 Convergence Cost

When the local model cannot complete a task that a frontier model can, the supervisor re-runs the task on the frontier path. The convergence cost is the *additional* supervisor effort to reach completion via re-routing — including the time to diagnose the local model's failure mode well enough to know that re-routing is the right move.

**Measurement: PlayerAgent V3 benchmark (2026-03-09 / 10, run `run_20260309_234818`).** Same 100-task task surface, three models:

| Model | Outcome | Wall-clock | Retries | Notes |
|---|---|---:|---|---|
| `claude-sonnet-4-6` | 100/100 | 5.6 min | 0 | direct frontier |
| `gemma3:27b` | 100/100 | 13.9 min | (HITL loop) | local + supervisor review |
| `gpt-oss:20b` | DNF (2× hard crash) | — | — | unrecoverable |
| `granite4:latest` | DNF (silent quality fail) | — | — | mechanical pass, content fail |

The two completing models reached the same correctness outcome on the same task surface. The local path was 2.5× slower wall-clock *and* required additional supervisor session-budget per HITL iteration (the audit-cost line item). The frontier path required zero supervisor review beyond the operator-driven prompt. For tasks where the local model DNFs (the `gpt-oss:20b` and `granite4:latest` rows), the entire local-lane cost is wasted; the convergence path is the full frontier-lane cost on top of the already-burned local lane.

---

## 3. Distinguishing From Paper 1.21

`PRIVACY_IS_WORTH_PAYING_FOR.md` is the foundational companion. It establishes that the local lane is not free *at inference*: 1.83× total-token use, 3.37× output-token use, 2.45× wall-time, 1/3 first-pass success vs. 3/3 on the DocDrop synthetic-fixture lane (`docs/domain_runs/PRIVACY-DOCDROP-001/comparison_report.md`). 1.21's frame is *privacy is the legitimating reason to pay the cost*. Its measurements are inference-side: tokens emitted by the local model, retries the local model needs, wall-time the local model takes.

This paper's frame is different. The cost being measured is the **supervising frontier operator's session budget**, which 1.21 does not address. When local inference is paired with frontier supervision (HITL, multi-agent, audit-and-sign-off workflows), the frontier model spends billable tokens that are not visible in any inference comparison. 1.21 prices the local lane *in isolation*; this paper prices the local lane *as supervised in production*, which is how the cost actually accrues.

The two papers land as a pair. 1.21 closes the inference-side loophole. This paper closes the supervision-side loophole.

---

## 4. Retrospective Evidence — Ten Historical Workflows

The full evidence packet is at `docs/domain_runs/COST-RETRO-001/report.md`. Ten historical workflows in the Project Phoenix repo were inspected for frontier-token audit/repair cost. The summary table:

### 4.1 Outcome Classification

| Outcome | Workflows | Total documented repair/audit turns | Supervisor-cost signature |
|---|---|---:|---|
| ACCEPTED (clean first-pass) | ORCHESTRATION_001 (both lanes); SLOW-001 gemma3:27b lane; PTS-001 gemma3:27b lane; COST-PROBE-001 data-extraction surface | 0 | Either no audit applied, or audit produced a narration-flag without repair |
| REPAIRED (supervisor intervention required) | DBB-005 gemma4_local; TSP_3090 / Paper 1.25 cycle; GRAFANA-OBS-001 multi-agent handoff | 5 + ~`hours` + 1 = at least 7 documented turns plus one major rewrite cycle | Concentrated: each REPAIRED case absorbed substantial frontier session-time |
| REJECTED (local output discarded) | SLOW-001 gemma4:26b on synthesis; PTS-001 gemma4:31b and gemma4:26b; PRIVACY-DOCDROP-001 quality lane; CAP-001 LLM lane; RETRIEVAL_001 Lanes B2/C; COST-PROBE-001 fixture-02 narration label | 0 (decision was to discard) | Audit cost = the diagnostic step itself; downstream cost = whatever was lost by not shipping |
| ABANDONED (memory-cited) | PlayerAgent V3: `gpt-oss:20b`, `granite4:latest`, `qwen3.5:27b` | n/a | Convergence cost; not directly inspectable from `docs/domain_runs/` |

The strongest cost-shift signal is concentrated in the REPAIRED class, not in the volume of supervised-correctness cases. Three workflows account for the bulk of documented repair cost:

- **DBB-005 gemma4_local**: 5 repair turns (3 automated + 2 manual supervisor interventions) plus a remediation rewrite at commit `a921cf4`. Outcome: PASS_WITH_WAIVER. Documented at `docs/domain_runs/DBB-005/gemma4_local/supervisor_verdict.md` and `repair_log.txt`.
- **TSP_3090 / Paper 1.25 cycle**: hours of Claude session-time absorbed by the audit-rewrite cycle. The cost asymmetry between the original Gemini commit (minutes) and the recovery (hours) is the mechanism made measurable.
- **GRAFANA-OBS-001 multi-agent handoff**: Gemini CLI hit a capability boundary (couldn't write Rust to the upstream `labwired-core` repo); Claude Sonnet 4.6 took over and implemented the missing `shm_i2c` device (PR #87). Cross-agent handoff *is* the repair turn here.

### 4.2 Bounded Counterexamples

Three concrete counterexamples surfaced where the cost-shift claim does *not* bind:

**ORCHESTRATION_001** — `gemma4:26b` at N=20 produced 100% accuracy on both Lane A (direct) and Lane B (orchestrated) for bounded complex-scheduling tasks. Zero supervisor turns invoked. The deterministic-output validation collapses the audit surface to a pass/fail check — no narration surface to drift, no repair to absorb supervisor cost. Bounded scheduling with crisp validation is the cleanest in-pipeline counterexample.

**SLOW-001 gemma3:27b lane** — 3/3 first-pass success on bounded strict-output DocDrop extraction. Zero supervisor turns invoked in SLOW-001 itself; an audit added later in COST-PROBE-001 caught a *narration-surface* flag (sentiment-tone flattening, 1 of 3 fixtures) but did not produce a repair pass. On the data-extraction half of the task (titles, attendees, action items, dates), the local model is mechanically reliable; the audit-cost surface is the narration half (sentiment label), which is THE_NARRATION_SURFACE_STUB.md's territory, not generic audit cost.

**CAP-001** — bounded-predicate task class where the right architectural answer is to *eliminate the LLM* and use a spec-aware deterministic function instead (`llama3.1:8b` at 75% vs. spec-aware function at 100%; `gemma4:26b` matched 100% but at 11× the spec-aware function's wall-time). There is no supervisor audit turn to count, because the correct decision is not to involve an LLM in the pipeline. This is a structurally different counterexample shape than ORCHESTRATION_001 and SLOW-001 — it bounds the claim from *outside* the LLM pipeline rather than from within.

**RETRIEVAL_001** is a fourth-shaped candidate (LLM-as-passenger in a retrieval task — 7× latency tax for no value-add) that pairs with CAP-001 architecturally. Same shape: the LLM doesn't belong in the pipeline; "audit it more carefully" is the wrong response.

---

## 5. Engaging Inference-Side Optimizations (MTP / Speculative Decoding)

Contemporary inference-side optimizations — multi-token-prediction (MTP) drafters, speculative decoding, parallel sampling — narrow the gap this paper argues against, but only on the surface this paper does not measure. The distinction is load-bearing and worth engaging directly.

The relevant 2026 example: Google DeepMind announced Gemma-4 MTP drafters claiming "up to 3× inference speedup" with "zero degradation in output." Popular developer commentary frames this as *"park this on self-hosted hardware and offload a bunch of major tasks to it instead of your expensive frontier API queues"* — the exact intuition this paper critiques.

### 5.1 What MTP Optimizes

- **Local-model wall-clock and GPU throughput.** Real and useful. The drafter predicts tokens; the main model accepts or rejects against its own sampling distribution; net effect is a generation-side speedup.
- **Convergence cost** (§2.3) — to a degree. Faster local generation means faster retries when the local lane fails to converge. Reduces the wall-clock penalty on the local-lane failure-and-retry loop.

### 5.2 What MTP Does Not Touch

- **Audit cost** (§2.1). The supervisor still has to read the local-model output to verify correctness, regardless of how fast the output was generated. Faster output may even *increase* per-unit-time audit load on the supervisor.
- **Repair cost** (§2.2). When the local-model output is wrong, the supervisor still spends frontier tokens diagnosing and fixing it. Inference speed has no effect on fabrication rate.
- **The "zero quality loss" claim itself.** This is a *theoretical* invariant — speculative decoding preserves the main model's sampling distribution when drafter predictions are accepted only on match. It is not an *operational* invariant about all downstream task surfaces. Subtle drift in agentic loops, long-form output, or code generation can fall below standard benchmark sensitivity while showing up at narration surfaces (per `THE_NARRATION_SURFACE_STUB.md` and `docs/domain_runs/NARRATION-REPL-001/partition.md`). The "zero degradation" claim is precisely the kind of load-bearing product claim that benefits from probe-level verification rather than benchmark-level acceptance.

### 5.3 The Relative Argument Strengthens

As inference-side optimization narrows the visible local-lane penalty (the part 1.21 measures), the *ratio* of supervisor-side cost to total cost goes up. A 3× inference speedup that leaves audit cost unchanged makes audit a larger fraction of all-in cost, not a smaller one. The hidden cost becomes more visible by relative weight, not less.

**The defensible synthesis.** MTP-class optimizations are good for the local lane at what they optimize. The popular extension — *therefore offload from frontier API queues* — does not follow, because the surface that determines all-in cost when correctness is required (the supervisor's audit and repair budget) is unaffected by the optimization. The local lane is faster and cheaper at *what local does*; it is not free at *what production correctness requires*.

---

## 6. The Local LLM Operator Judgment Cluster

This paper consolidates a thesis that the cluster's prior papers (1.20–1.25) approached piecewise:

- **1.20 (`GEMMA_4_IS_SMARTER_GEMMA_3_IS_SAFER`)** — handoff discipline costs operator review time.
- **1.21 (`PRIVACY_IS_WORTH_PAYING_FOR`)** — privacy is worth paying for; the local lane is not free at inference.
- **1.22 (`SLOW_IS_NOT_SMART`)** — slow is not smart; scaling local up regresses on bounded tasks.
- **1.23 (`PLEASE_IS_SAND_OFF_A_BEACH`)** — ritual-vs-structural cost.
- **1.24 (`THE_MODEL_IS_NOT_THE_FUNCTION`)** — visible code simplicity hides system complexity.
- **1.25 (`ORCHESTRATION_IS_CHEAPER_THAN_REASONING`)** — scaling local up is anti-dividend on hardware-bound systems; the optimal use of intelligence is as an interface/explanation layer.

Each cluster paper touches a piece of the cost picture. None states the claim that ties them together: *the cost the local lane appears to save is paid in frontier tokens elsewhere in the same workflow.* Without this paper, the cluster reads as a set of related observations. With it, the cluster has a spine.

The claim is counter-intuitive in the broader open-source / local-inference vernacular, which sells "no API bill" as equivalent to "no cost." The cluster's existing papers chip at this; this paper consolidates to the strongest defensible form: *the model is not free if its supervisor is not free.*

---

## 7. Proof Boundary

The cost-shift claim binds on task classes that simultaneously satisfy two conditions:

1. **Supervised correctness is required.** The task's output must be verified before consumption. Tasks where the user accepts the raw local-model output without independent verification do not invoke supervisor cost.
2. **Verification has non-trivial overhead.** The task's correctness cannot be checked by a one-line validator or a deterministic comparison. Tasks with crisp pass/fail validation (numeric outputs against ground truth, JSON schema validation) collapse the audit surface and bound the cost-shift argument.

The claim does **not** bind on:

- **Bounded task classes where the local model converges cleanly** (ORCHESTRATION_001, SLOW-001 gemma3:27b — §4.2).
- **Task classes where the correct architecture eliminates the LLM** (CAP-001 — §4.2).
- **Pure-exploration / draft-only writing** where verification is unneeded by design.
- **Private-data tasks where audit is impossible regardless of cost** — the local lane is the *only* lane, so the cost comparison is moot (this is 1.21's territory).

The strongest form of the claim, defensible without overreach: *for any task class with non-trivial verification overhead and supervised correctness requirements, the all-in token cost (local + frontier audit) exceeds the inference-only cost the local-lane marketing implies, and may exceed direct frontier execution.*

---

## 8. Limitations and Open Questions

What this paper does not measure:

- **Per-turn frontier-token attribution for most workflows.** Only COST-PROBE-001 instrumented `/usage` delta per supervisor turn. DBB-005's "2 manual supervisor interventions" and TSP_3090's "hours of Claude session-time" are qualitative; per-turn token / budget breakdowns are not reconstructable from the artifacts.
- **PlayerAgent V3 benchmark not in `docs/domain_runs/`.** The canonical 100-task convergence case lives under `domains/SensorAgents/TennisAgent/`. Numbers are summarized in memory but not in the inspectable retrospective tree.
- **Cost-of-not-auditing remains hypothetical.** COST-PROBE-001 documented one narration-surface failure (sentiment-tone flattening on fixture_02) that would have shipped without audit. The downstream cost of that ship-through (what damage a flattened sentiment label does to a real consumer of the extraction) is hypothetical, not measured.
- **No cross-model audit-cost comparison.** All audit-instrumented runs used `gemma3:27b`. Whether `gemma4:26b`, `gemma4:31b`, `llama3.1:8b`, or other local models would generate more or fewer narration-surface failures (driving higher or lower audit cost) is open.
- **Heavy-tailed repair cost is undercounted.** DBB-005's "5 repair turns" understates supervisor work because the remediation rewrite (commit `a921cf4`) was treated as supervisor work outside the harness loop. Similarly TSP_3090's "Paper 1.25 audit cycle" was not turn-counted in the artifacts. The actual frontier-token spend on REPAIRED cases is almost certainly larger than the discrete turn counts suggest.

What would tighten the paper for future work:

- A larger task-level rate measurement on the same fixture class, with a second operator-state baseline (the gate-spec retired execution path called for this; the operator-mode probe was retired due to its own friction, but an API-mode equivalent would close the gap).
- Cross-model audit-cost comparison on a fixed task class.
- A designed probe of cost-of-not-auditing: run the same task class with deliberate no-audit local-lane execution; measure the rate at which fabrication ships.

---

## 9. Conclusion

Three claims, each bounded as documented above:

1. **Audit, repair, and convergence costs are real, measurable, and concentrated in the supervisor's frontier session budget.** COST-PROBE-001 measured ~1% Claude session-budget per supervisor turn on the DocDrop fixture class. The Paper 1.25 audit cycle absorbed hours of Claude session-time as a single instance.
2. **The cost-shift claim binds on supervised-correctness tasks with non-trivial verification overhead.** It does not bind on bounded task classes with deterministic-output validation (ORCHESTRATION_001, SLOW-001) or task classes where the LLM doesn't belong in the pipeline (CAP-001). The boundary is task-class-conditional, not absolute.
3. **Inference-side optimization (MTP / speculative decoding) sharpens the relative argument, not weakens it.** Audit and repair costs are unaffected by inference speed; as inference speed improves, audit becomes a larger fraction of all-in cost.

The cluster's prior papers each touched a piece of the cost picture. This paper's contribution is the spine that connects them: the cost the local lane appears to save is paid in frontier tokens elsewhere in the same workflow. The model is not free if its supervisor is not free.

---

## Appendix A — Reproducibility Artifacts

| Claim | Artifact / verification |
|---|---|
| Per-supervisor-turn cost on DocDrop fixtures (~0.83%) | `docs/domain_runs/COST-PROBE-001/report.md`, table §"Results" |
| DBB-005: 5 repair turns + 2 manual supervisor interventions | `docs/domain_runs/DBB-005/gemma4_local/supervisor_verdict.md`, `repair_log.txt` |
| Paper 1.25 audit cycle | `docs/ORCHESTRATION_IS_CHEAPER_THAN_REASONING.md` (post-repair source); `GEMINI_FAILURE_MODES.md` entry #6 |
| GRAFANA-OBS-001 multi-agent handoff | `docs/domain_runs/GRAFANA-OBS-001/PHASE_SUMMARY.md`; upstream PR #87 = commit `3e7ba90` in `w1ne/labwired-core` |
| ORCHESTRATION_001 bounded counterexample | `docs/domain_runs/ORCHESTRATION_001/report.md` |
| SLOW-001 bounded counterexample | `docs/domain_runs/SLOW-001/docdrop_model_matrix_report.md` |
| CAP-001 architectural counterexample | `docs/domain_runs/CAP-001/report.md` |
| Retrospective evidence packet | `docs/domain_runs/COST-RETRO-001/report.md` |
| PlayerAgent V3 benchmark (convergence cost) | memory entry `run_20260309_234818`; partially documented under `domains/SensorAgents/TennisAgent/` |

---

## Appendix B — What This Paper Does Not Claim

- That all local-inference workflows cost more than frontier execution. The claim binds only on supervised-correctness tasks with non-trivial verification overhead (see §7).
- That local-model failure rates are universally high. The claim is about the *concentration* of supervisor cost in REPAIRED outcomes, not about the prevalence of failures. `gemma3:27b` on DocDrop strict-output extraction passed 3/3 cleanly (SLOW-001).
- That inference-side optimizations are worthless. MTP / speculative decoding do useful work for the local lane (§5.1). The paper's claim is that they do not touch the surface this paper measures.
- That the catalog rate (72% narration-surface across cataloged failures, per `NARRATION-REPL-001/partition.md`) is an unbiased fabrication-rate estimate. The catalog has no denominator; it conditions on *being a failure*, not on *being a task*. The COST-PROBE-001 task-level rate (33% on DocDrop sentiment-tone with gemma3:27b) is the more honest estimate, with the caveat that it is single-model and single-fixture-class.
- That the retrospective's 10 workflows generalize beyond this repo, this agent set, or this ~6-week observation window. The packet is exploratory evidence, not a benchmark.

---

## Appendix C — Voice Discipline

The cluster's voice-signature catalog (in `docs/AGENT_AUDIT_PROTOCOL.md`) flags phrases like *"factor of infinity," "nuclear bomb," "elite Systemic AI space,"* and the closure-reflex register (*"Mission Complete," "officially closed"*). The counter-intuitive headline ("local models cost frontier tokens") is load-bearing for the paper's interest; the supporting prose should not inflate beyond what the evidence supports. This draft has been authored against the catalog and reviewed for closure-reflex drift before commit.

The strongest form of the claim — and the form this paper should defend — is bounded: *for any task class with non-trivial verification overhead, the all-in token cost (local + frontier audit) exceeds the inference-only cost the local-lane marketing implies, and may exceed direct frontier execution.* Falsifiable, bounded, defensible. Anything stronger ("local always costs more") is overreach; anything weaker ("local sometimes has overhead") is not the paper.

---

*Active draft begun 2026-05-20. Phoenix-side authoring; all evidence anchored in `docs/domain_runs/COST-RETRO-001/report.md` and the artifacts it cites. No new probe runs performed for this draft.*
