# Slow Is Not Smart

## Status

Frozen.

This paper line is frozen after the SLOW-001 DocDrop model-matrix packet plus
the PTS-001 synthesis matrix and 3-run replay. The projected
synthesis-counterexample failed in the strongest direction — `gemma4:31b`
regressed in 4/4 runs against a fixture that `gemma3:27b` handled cleanly
first try.

Evidence packets:

- `docs/domain_runs/SLOW-001/docdrop_model_matrix_report.md` — bounded
  strict-output extraction
- `docs/domain_runs/PTS-001/comparison_report.md` — synthesis matrix
  (`gemma3:27b` 6/6, `gemma4:26b` parse_fail at 4096 tok, `gemma4:31b` 5/6
  with hallucinated date)
- `docs/domain_runs/PTS-001/replay/replay_aggregate.md` — 3-run replay of
  `gemma4:31b` on PTS-001 confirming the regression is systematic, not a
  one-off artefact

It is also a companion line to `GEMMA_4_IS_SMARTER_GEMMA_3_IS_SAFER.md`.
That paper makes the doctrine claim about handoff discipline. This one makes
the related sizing claim: model scale is not a substitute for task analysis,
validation, and a well-bounded lane.

## Working Claim

For the production-shape tasks Bulkhead τ actually deploys on — bounded
JSON handoff, schema-bound tool dispatch, document field extraction — model
size and decoding speed are not reliable quality signals. A slower, larger
local model may be the right choice for some workloads, but it must earn that
choice on the task surface being measured.

The narrower form of the claim:

- on strict-output tasks, the bottleneck is prompt + schema + receive-side
  validation, not model size
- on those tasks, `gemma4:26b` and `gemma4:31b` produce the same outcome at
  different speeds
- an operator choosing 30B+ local inference for these lanes may be paying
  latency and hardware cost for capability the lane does not use

The broader form of the claim:

- local-LLM decisions often treat larger models as obviously better
- the Project Phoenix evidence base does not support that assumption for the
  task surfaces it has measured
- the right question is not "what is the biggest model I can run?" but "what
  model is sufficient for this validated lane?"

## Why This Paper Exists

The hardware decision is real engineering work. A local model is not just a
model choice; it brings memory requirements, latency, thermal limits,
operator wait time, and maintenance obligations. Those costs are worth paying
when the workload needs them. They are waste when the lane is already bounded
by schema, validator, and deterministic orchestration.

There are at least three legitimate reasons to choose larger local capacity:

1. the operator has a real use case where 30B+ at 5-10 tok/s is the right tool:
   long context, multi-step reasoning, deep summarization over a single
   massive input
2. the operator is buying optionality: they want the headroom in case (1) becomes
   true for them later, even if it is not true now
3. the operator is assuming size equals quality without measuring the actual
   lane

This paper is about the third case. It does not argue against larger models.
It argues for measuring whether size matters on the task being deployed.

## How We Arrived Here

### 1. The DocDrop SLOW-001 experiment

A controlled experiment was conducted using the DocDrop task with synthetic
fixtures to compare the performance of `gemma3:27b`, `gemma4:26b`, and
`gemma4:31b`. The metrics captured included success rate, parse/schema
failures, token counts, and wall-time.

| Model       | Success Rate | Total Wall Time (s) | Notes                                    |
| :---------- | :----------- | :------------------ | :--------------------------------------- |
| `gemma3:27b`| 3/3          | 32.787              | All successful                             |
| `gemma4:26b`| 2/3          | 29.920              | One parse failure at max 2048 output tokens |
| `gemma4:31b`| 3/3          | 131.072             | All successful                             |

**Conclusion:** For this bounded DocDrop extraction task, `gemma3:27b` and
`gemma4:31b` achieved perfect success rates, but `gemma4:31b` was about 4x
slower. `gemma4:26b` was fastest overall but had one parse failure. The
strongest comparison is therefore `gemma3:27b` versus `gemma4:31b`: the smaller
model achieved the same validated outcome at a fraction of the wall-time. This
supports the claim that larger/slower models do not necessarily improve bounded
strict-output tasks enough to justify the cost.

### 2. The Project Phoenix evidence base

Two production-shape lanes already deployed and verified:

- DocDrop privacy-doc extraction: `gemma4:26b` `/no_think`, 5-field JSON
  output, schema-validated, runs at production speed. Verified end-to-end
  against real meeting documents.
- PPR Lane 2 strict tool-call dispatch: `gemma4:26b` `/no_think`,
  per-tool schema validation, exit codes 2/3/4 distinct on failure.
  Hardened code committed; live evidence capture in progress.

Both lanes use 26B. Neither needs more.

### 3. The 26B vs 31B contrast on strict-protocol probes

Same harness, same six bounded probes, two clean-capture rerun dates:

| Model | Mode | 2026-04-15 | 2026-04-28 (Ollama 0.20.0) |
|---|---|---|---|
| `gemma4:26b` | unsuppressed | 4/6 | 6/6 |
| `gemma4:26b` | `/no_think` | 6/6 | 6/6 |
| `gemma4:31b` | unsuppressed | 6/6 | (incomplete) |
| `gemma4:31b` | `/no_think` | 6/6 | (incomplete) |

The 31B advantage in April was that it cleared 6/6 unsuppressed where 26B
needed `/no_think`. Under Ollama 0.20.0 that gap closed upstream. As of the
April 28 rerun, the two models produce the same passing outcome on strict
tasks, with 31B running materially slower.

The 31B incomplete cell on April 28 is partly an honest signal: the rerun did
not finish cleanly because 31B is slow enough that the operator gave up. That
operator behavior is itself the paper.

### 4. The "slow is good for documents" framing

There is a recurring assumption that slower or larger models are better for
document scanning, OCR-adjacent extraction, or other ingestion-heavy work.

The DocDrop deployment is exactly that lane — bounded extraction from real
documents into a strict 5-field JSON contract — and it runs at production
speed on 26B. There is no point in the pipeline where a slower 31B (or
larger) would produce a better extraction. The bottleneck is the prompt and
the receive-side validator, not the model.

This is one of the cleanest places to test the conflation. If the paper
needs a single empirical anchor, this is it.

## Measured Counterexample: PTS-001

The honest counterexample to SLOW-001 had to be a task that requires
synthesis rather than extraction. PTS-001 — Project Timeline Synthesis — is
that task. The model receives a mixed bundle of emails, meeting minutes, and
project updates, then must construct a chronological timeline, order explicit
and implied dates, identify conflicts between delays and firm deadlines,
notice suggestions that were later overridden, and produce impact statements
that explain timeline, cost, or scope risk.

The hypothesis going in was that `gemma3:27b` and `gemma4:26b` might extract
many events but struggle with ordering, conflict detection, and impact
analysis, while `gemma4:31b` would have a plausible chance to produce a
stronger synthesis — earning its wall-time cost.

That hypothesis did not survive the measurement.

Single fixture (`tests/fixtures/pts_synthetic/fixture_pts_001.txt`),
three-model matrix, one-shot, no retries. Full ledger:
`docs/domain_runs/PTS-001/comparison_report.md`.

| Model         | Outcome     | Wall (s) | Output tok | Quality probes |
| :------------ | :---------- | :------- | :--------- | :------------- |
| `gemma3:27b`  | success     | 26.93    | 770        | **6 / 6**      |
| `gemma4:26b`  | parse_fail  | 47.54    | 4096 (cap) | n/a            |
| `gemma4:31b`  | success     | 133.98   | 758        | 5 / 6          |

The "quality probes" are heuristic, not human-judged: chronological ordering,
StarStream-override detection, deadline-slip detection, and substantive impact
analysis on the override and the firm deadline. The point lost by `31b` was
chronological order, because the model emitted a hallucinated date
`"2026-63-26"` (impossible month 63) and placed it out of sequence in the
timeline. `gemma3:27b` also captured multi-owner attribution on joint
meetings, which `31b` collapsed to single-owner rows.

`gemma4:26b` failed in the same way SLOW-001 documented: ran the output budget
out without finishing the JSON. Doubling `num_predict` from 2048 to 4096 did
not save it on the synthesis surface — the model was verbose enough to
exhaust the larger budget too.

The headline finding for the paper: on this single synthesis fixture, the
slower / larger model was **both slower and worse**. It paid roughly 5x the
wall time of `27b` and produced a hallucinated impossible date plus reduced
owner attribution. The failed counterexample matters because PTS-001 was the
lane where larger size was supposed to have the best chance to win.

This makes the working claim broader rather than narrower. The single-fixture
caveat still applies: PTS-001 is n=1, the probes are heuristic, the
hallucinated date could be a generation artefact rather than a systematic
regression. A second fixture or a 3-run repeat on the same fixture is the
reasonable hardening step before the synthesis-lane claim is treated as
load-bearing.

## Where Size Might Genuinely Matter

The paper should not overclaim. There are real task surfaces where larger
local models earn their cost:

- very long context (single document or thread well past 32k tokens)
- multi-step reasoning where 26B plateaus and 31B+ does not
- creative or open-ended summarization where output quality is judged by a
  human reader, not a strict validator
- agentic loops where the model needs to make many small judgment calls
  without supervision

None of these are the strict-handoff lanes Project Phoenix deploys on. All
of them deserve a fair audit if this paper line is going to be honest about
where the conflation breaks down.

## What This Paper Is Not

- Not a general benchmark of Gemma-family models
- Not a claim that larger local models are useless
- Not a recommendation to avoid local hardware investment
- Not a claim about every long-context or open-ended reasoning workload

## What This Paper Is

- A bounded operator lesson from Project Phoenix lanes
- A warning against treating latency or model size as a proxy for quality
- A reminder that strict-handoff systems are often limited by prompt,
  schema, validator, and orchestration design rather than by raw model size
- A case for choosing the smallest model that clears the lane with acceptable
  quality, reliability, and latency

## What Would Strengthen The Frozen Claim Further

These are nice-to-haves, not freeze blockers:

- A dated market snapshot — Mac Mini availability, ordering lead time, the
  specific configurations buyers are choosing.
- Public-signal sample — Reddit / HN / discord discussions about why buyers
  are choosing 30B+ class hardware over smaller local lanes.
- A second synthesis fixture (different domain) to extend the synthesis-lane
  finding beyond a single project-timeline shape.

## Current Rule

This document is Frozen.

The DocDrop bounded-extraction lane and the PTS-001 synthesis lane both
support the same finding: the smaller, faster, supposedly less capable model
produced the better outcome. The 31b regression on PTS-001 is reproducible
across four runs in three distinct failure modes — broken chronology in 3/4,
hallucinated impossible date in 1/4, dropped required field in 1/4 — while
27b handled the same fixture cleanly first try.

The freeze is bounded as the paper writes it: the claim is about strict-
handoff and timeline-synthesis lanes Project Phoenix actually deploys on, not
about every conceivable use of a local LLM. Lanes where larger size genuinely
helps (very long context, deep summarisation, agentic loops) remain
explicitly out of scope.
