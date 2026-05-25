# Smarter, Faster, and Bounded by Handoff Discipline

## Status

Frozen 2026-04-29. Promoted from active draft on the basis of:

- The corrected protocol-probe matrix (clean-capture rerun, 2026-04-15) that
  invalidated the original 0/6 reading of `gemma4:26b`
- The DocDrop production deployment of `gemma4:26b` `/no_think` driving
  strict 5-field JSON extraction in a real privacy-bounded pipeline
- A captured PPR Lane 2 live evidence packet that, across three runs of the
  same eight canonical probes, repeatedly catches model-side parameter
  mutation at the validator boundary (RC=3) — the adversarial complement to
  DocDrop's positive deployment case
- A third dated regression datapoint that strengthened, rather than weakened,
  the doctrine: the unsuppressed lane drifted again between 2026-04-28 and
  2026-04-29 (`6/6 → 5/6`), exactly the kind of motion the regression probe
  exists to catch

## Thesis

Frontier-class local models like Gemma 4 are smarter and faster than their
predecessors, but their default verbose-reasoning posture breaks rigid
machine-to-machine JSON handoffs. The operational lesson is not to avoid the
smarter model. It is to enforce **handoff discipline** at the deployment
boundary. With `/no_think` suppression and a schema-bound output contract,
the same `gemma4:26b` that previously appeared dangerous clears 6/6 strict-
protocol probes and can be made safe for bounded deployment surfaces through
strict receive-side discipline.

This is engineering doctrine, not a bug discovery.

## How We Arrived Here

### 1. The original false read

The first bounded protocol probe of `gemma4:26b` returned `0/6` across three
desktop runs. Every output landed as `non_json`. Read at face value, this
looked like a within-family regression: `gemma3` was passing 3/6–5/6 on the
same harness; `gemma4` had collapsed to 0/6 while running fast and producing
clean bundles.

That read prompted the original framing of this paper line: same family,
same harness, same lane — and the newer model couldn't stay inside the
protocol. The provocative "more dangerous" question mark followed naturally.

### 2. The capture-pipeline finding

On 2026-04-15, the harness was instrumented to compare `ollama run`
subprocess capture against the Ollama REST API directly. The legacy path was
capturing raw terminal output including VT100 cursor-rewrite sequences (e.g.
`\x1b[6D\x1b[K`) that Ollama uses for its streaming display. Those codes
corrupted multi-line JSON at the content level — irrecoverable by post-hoc
ANSI stripping.

Models without thinking-mode preambles (`gemma3`, `qwen2.5`) were
comparatively immune because their output streamed in a more linear shape.
Thinking-mode models (`gemma4`, `gpt-oss`) took the worst hits because the
preamble-then-answer interleave amplified the corruption.

The fix was a one-line transport switch: `/api/generate` with
`stream: false`. The legacy `ollama_run` path remains, gated behind a flag,
for reproduction.

The original 0/6 measurement was filed upstream as
`google-deepmind/gemma#604`. The corrected matrix in §3 below was posted
as a follow-up comment to that issue on 2026-04-16; the issue remains open
pending an upstream determination on whether unsuppressed `gemma4:26b`
flat-schema discipline is expected behavior, or whether the recommended
default for machine-facing JSON use cases is suppression.

### 3. The corrected matrix (2026-04-15 clean capture)

Same harness, same probes, clean capture:

| Model | Mode | Pass |
|---|---|---|
| `gemma3:27b` | — | 5/6 |
| `qwen2.5:14b` | — | 4/6 |
| `gemma4:26b` | unsuppressed | 4/6 |
| `gemma4:26b` | `/no_think` suppressed | **6/6** |
| `gemma4:31b` | unsuppressed | **6/6** |
| `gemma4:31b` | `/no_think` suppressed | **6/6** |

The 0/6 disappeared entirely. Unsuppressed `gemma4:26b` actually scores 4/6;
the two failing probes (PROTO_001, PROTO_004) are flat-schema cases where the
thinking preamble interleaves with JSON output even via clean transport.
Suppression closes that gap completely.

`PROTO_010` is the inverse signal: both `gemma3:27b` and `qwen2.5:14b` fail it
as a genuine multi-entity-reasoning content failure. `gemma4` passes it.
That single probe is the cleanest available evidence for "smarter" — it
isolates reasoning quality from protocol compliance.

### 2026-04-29 dated companion table (Ollama 0.20.0)

A second clean-capture matrix run on 2026-04-29 produced this companion
table. The setup is identical to the April-15 run; only the calendar date
and Ollama state have moved:

| Model | Mode | 2026-04-15 | 2026-04-29 |
|---|---|---|---|
| `gemma3:27b` | — | 5/6 | 5/6 |
| `qwen2.5:14b` | — | 4/6 | 4/6 |
| `gemma4:26b` | unsuppressed | 4/6 | 5/6 |
| `gemma4:26b` | `/no_think` suppressed | **6/6** | **6/6** |
| `gemma4:31b` | unsuppressed | **6/6** | _rerun pending (see note)_ |
| `gemma4:31b` | `/no_think` suppressed | **6/6** | _rerun pending (see note)_ |

> Note on `gemma4:31b` rows: the 2026-04-29 rerun against `gemma4:31b` was
> initiated as part of this matrix run but had not completed at freeze time.
> `gemma4:31b` is a ceiling reference for this paper, not the deployment lane;
> the bounded thesis rests on the `gemma4:26b` rows above. The fortnightly
> regression cadence will pick up the missing 31b rows on its next scheduled
> run; if a result lands earlier, this table will be updated post-freeze.

The April-15 framing of `gemma4:26b` unsuppressed as a 4/6 lane was already
softened by the 2026-04-28 regression run (6/6) and is softened further by
this 2026-04-29 row (5/6). The unsuppressed lane is consistent only in the
sense that it consistently moves. The suppressed lane stays at 6/6 across
both dates and is the contract production should anchor on.

`gemma3:27b` and `qwen2.5:14b` are stable across the two runs and continue to
serve as the content-failure controls for `PROTO_010`.

## The Handoff Discipline Solution

Two operational levers, both deployable today:

### Lever 1: thinking-mode suppression

The `/no_think` prompt prefix tells `gemma4` to skip its reasoning preamble
and emit the answer directly. It is one token at the top of the prompt.
On strict-protocol probes it moves `gemma4:26b` from 4/6 to 6/6.

That was the measured 2026-04-15 result. A later scheduled regression probe
on 2026-04-28 under Ollama `0.20.0` found that the unsuppressed gap had
closed on this machine: `gemma4:26b` scored 6/6 both unsuppressed and
suppressed. The operational lesson is therefore slightly stronger than the
April matrix alone suggested: suppression is a **defensive default**, not an
untouchable law of nature. The contract that matters is not "always suppress"
but "probe the lane often enough to detect drift before production trust is
affected."

### Lever 2: schema-bound output contract

The Ollama REST API exposes a `format: "json"` constraint that forces decoded
output to be parseable JSON. Combined with an explicit schema in the prompt
and a typed validator on the receiving side, the deployment surface becomes:

```
prompt: /no_think + schema  →  format: "json" enforced at decode  →
strict typed validator at receive  →  exit 2 (parse) or 3 (schema) on failure
```

A failure at any stage is observable, not a silent corruption of downstream
state. The model is allowed to be verbose if it wants to — the deployment
boundary is what stays disciplined.

## Drift Addendum (2026-04-15 → 2026-04-28 → 2026-04-29, Ollama 0.20.0)

Three dated runs are now on record. The unsuppressed lane has moved on every
run. The suppressed lane has stayed at 6/6 across all three. That is the load-
bearing observation behind the doctrine.

| Model | Mode | 2026-04-15 | 2026-04-28 | 2026-04-29 |
|---|---|---|---|---|
| `gemma4:26b` | unsuppressed | `4/6` | `6/6` | `5/6` |
| `gemma4:26b` | `/no_think` suppressed | `6/6` | `6/6` | `6/6` |
| `gemma3:27b` | unsuppressed | `5/6` | `5/6` | `5/6` |
| `qwen2.5:14b` | unsuppressed | `4/6` | _not installed_ | `4/6` |

Interpretation:

- the April clean-capture correction remains valid across all three runs
- the `/no_think` suppression contract for `gemma4:26b` is **stable**
  (`6/6 → 6/6 → 6/6`) — the production lane has not moved
- the unsuppressed lane is **not stable** (`4/6 → 6/6 → 5/6`) — relying on
  `gemma4:26b` without suppression is exactly the surface a deployment
  contract needs to defend against
- the gap between unsuppressed and suppressed is small in absolute terms
  (one probe), but it is a real, repeatedly-observed signal, not a one-shot
  artifact
- the regression probe did the job it was built for: it caught a movement on
  its first run, and the subsequent run confirmed the lane is dynamic enough
  to warrant a defensive default rather than a one-shot stability claim

The 2026-04-29 failing probe in the unsuppressed run was `PROTO_001`, where
`gemma4:26b` emitted decimal win percentages (`0.556`, `0.513`) instead of
percentage values (`55.6`, `51.3`). The output was clean JSON — the model
simply chose a different value contract than the schema asked for. That is the
exact failure mode strict receive-side validation is designed to catch.

The upstream variable across these runs is Ollama `0.20.0`. This is not
enough evidence to assign causality narrowly to Ollama itself; it is enough to
state that the live deployment surface keeps changing under fixed model and
version labels.

The doctrine therefore freezes as follows: keep `/no_think` as the production
default for `gemma4:26b`, but treat it as a **defensive default backed by a
fortnightly regression probe**, not as a timeless requirement. The next probe
is due 2026-05-13. The exact run command lives in
`docs/GEMMA_PROTOCOL_VERIFICATION_RUNBOOK.md`.

## Two Bounded Cases

The doctrine is supported by two bounded cases that exercise it from
opposite directions.

- **Case 1 (DocDrop)** is the positive bounded deployment case: a real
  privacy-bounded pipeline where `gemma4:26b` `/no_think` drives strict
  5-field JSON extraction end-to-end against real meeting documents.
- **Case 2 (PPR Lane 2)** is the adversarial bounded handoff case: a
  three-run evidence packet that repeatedly demonstrates `gemma4:26b`
  mutating machine-facing parameters at the validator boundary, and the
  receive-side contract catching every mutation at RC=3.

The two cases are deliberately asymmetric. Case 1 demonstrates the doctrine
at work in a successful deployment; Case 2 demonstrates why the doctrine is
necessary in the first place. Together they bracket the same operational
claim from above and below.

### Case 1. DocDrop

The DocDrop privacy-doc analysis pipeline is the production-grade document
extraction case for the handoff-discipline thesis. The use case is bounded
but real:

- Sensitive meeting documents on USB media (`.docx` / `.pdf`)
- Local-only inference (Ollama on `localhost`, no data egress)
- Per-document map step → 5-field JSON summary
- Reduce step → final Markdown report

The map step uses `gemma4:26b` with `/no_think` and `format: "json"`. A
receive-side validator type-checks five required fields
(`document_title`, `executive_summary`, `key_action_items`,
`meeting_participants`, `sentiment_tone`). The orchestrator advances its
progress file only on `RC=0`; parse failures (exit 2) and schema failures
(exit 3) are first-class signals — the orchestrator skips the document
without corrupting the run.

This is exactly the deployment shape the thesis predicts. The smarter
model now runs in a privacy-safe lane it would have been disqualified from
under the original false read. Pipeline run and verified end-to-end against
real meeting documents.

### Case 2. PPR Lane 2 Tool Dispatch

The second bounded case is a local `PPR_Agent` query-parser surface where the
model is not allowed to answer from memory. It emits one JSON tool-call object
for a deterministic SQLite-backed medical-device substrate.

The strict deployment shape is the same:

- Local-only inference (`localhost:11434`, Ollama REST API)
- `gemma4:26b` with `/no_think`
- `format: "json"` enforced at decode
- receive-side validation of `tool` plus per-tool parameter schema
- deterministic dispatch only after validation passes
- explicit failure contract: exit 2 (parse/transport), exit 3 (schema),
  exit 4 (dispatch)

This case matters because it exercises a different kind of machine-facing
handoff than DocDrop. The output is not a five-field document summary. It is a
bounded action object whose only job is to select a deterministic tool and
typed argument set without corrupting the authority boundary.

This is an adversarial bounded handoff case, not a clean-success case. The
strict PPR Lane 2 surface is implemented, evidenced, and validator-correct.
The model-facing side is not "production-stable" in the DocDrop sense: across
three runs of the same eight probes on the same Ollama version, `gemma4:26b`
emits a different malformed parameter object on a different probe each time.
That instability is the point — it is exactly what the receive-side validator
exists to catch, and the captured packet shows it doing so on every observed
failure at RC=3.

The packet exercises the eight canonical Lane 2 probes through `ppr_ollama.py`'s
strict surface and records, for each probe: the raw model response, the
validated tool-call payload (or `null` on rejection), the normalized
parameters, the exit code, and the latency.

The eight probes cover the parameter coverage matrix for the six legacy PPR
tools, including one deliberate negative case:

| Probe | Coverage | Expected exit |
|---|---|---|
| `PPR_LANE2_001` | scalars + optional category | `0` |
| `PPR_LANE2_002` | range + optional category | `0` |
| `PPR_LANE2_003` | list + range + alias normalization | `0` |
| `PPR_LANE2_004` | optional integers only | `0` |
| `PPR_LANE2_005` | range + multi-word company alias | `0` |
| `PPR_LANE2_006` | string search term | `0` |
| `PPR_LANE2_007` | full optional surface for `get_top_devices` | `0` |
| `PPR_LANE2_008` | invalid company in list (negative case) | `3` |

Three dated runs were captured during freeze (2026-04-29, Ollama `0.20.0`):

| Run | Stamp | Pass rate | Notes |
|---|---|---|---|
| 1 | `ppr_lane2_evidence_20260429T235929Z` | 4/8 | exposed two prompt/validator inconsistencies (`category` vs `device_category`, `query` vs `search_term`); fixed in `ppr_ollama.py` `SYSTEM_PROMPT` |
| 2 | `ppr_lane2_evidence_20260430T000100Z` | 5/8 | post-fix; remaining failures all genuine model-side schema drift |
| 3 | `ppr_lane2_evidence_20260430T000304Z` | 3/8 | post-fix; same probe set, different failure distribution |

Across the three runs, the validator never returned a false positive — every
failure was either a real prompt-design bug (run 1) or a genuine model-side
schema mutation (runs 2–3). The 2026-04-30 model-side failure modes the
validator caught include:

- truncated/garbled JSON literals (`"start_year": 202\t}`)
- hallucinated parameter names (`end_imbalance_year`, `end_lag`, `end_im_year`,
  `device_company_category`, `search_quadra_term`)
- transport timeout on a malformed-input case (negative probe)

These are exactly the failure modes a deterministic dispatch surface must
defend against. Without strict receive-side validation, every one of them
would either crash the SQLite layer or, worse, dispatch with the wrong typed
arguments and return data that looked plausible but was wrong.

The headline observation is therefore not the pass rate — it is that the
boundary is correctly engineered (every malformed payload was rejected with
an observable exit code, and the deterministic substrate was never reached
with one) while the model-facing side keeps mutating machine-facing
parameters often enough that the validator is load-bearing rather than
decorative. That is the bounded operational claim the paper makes for Case 2:
the boundary works, and the boundary is necessary, both demonstrated on the
same packet.

Per-probe artifacts and manifests live under
`domains/DemoAgents/PPR_Agent/benchmark/results/`. The runner is
`scripts/ppr_lane2_evidence_run.py` and the canonical probe set lives at
`domains/DemoAgents/PPR_Agent/benchmark/queries/ppr_lane2_canonical_probes.json`.

## What This Paper Is Not

- Not a frontier-safety statement about Gemma 4
- Not a claim that thinking-mode is bad
- Not a claim that local models replace frontier capability for arbitrary tasks
- Not a model-quality benchmark — the protocol probes are six bounded
  surfaces, not a general competence test

## What This Paper Is

- A bounded operational claim about strict-handoff lanes
- A concrete accounting of how the original measurement was wrong, and how
  it was caught
- Two bounded case studies showing the deployment discipline that makes
  verbose reasoning models usable in machine-to-machine pipelines

## What Would Strengthen The Paper Further

The freeze-time strengtheners (regression probe, dated matrix rerun, PPR
evidence packet) all landed and are referenced inline above. The remaining
items are post-freeze strengtheners — useful, but not load-bearing for the
bounded thesis as frozen:

- A short comparison row for a small frontier model under the same strict-
  output prompt (template at `docs/CLAUDE_HAIKU_STRICT_ROW_TEMPLATE.md`).
  This positions local Lane 2 against the cheapest frontier alternative.
  Deferred at freeze because the operator's frontier API access path was
  unavailable; can be added without touching the bounded thesis.
- Additional time-spaced regression-probe runs beyond the three dated runs
  on record. The fortnightly cadence is captured in
  `docs/GEMMA_PROTOCOL_VERIFICATION_RUNBOOK.md`. Each subsequent run either
  reinforces the suppressed-lane stability claim or surfaces a new drift
  signal worth documenting.

## References

- Capture-pipeline correction (memory): `project_openclaw_protocol_finding.md`
- Corrected matrix artifacts: `docs/MODEL_COMPARISON_PACKET_GEMMA_PROTOCOL.md`
- Protocol stability packet: `docs/GEMMA_PROTOCOL_STABILITY_PACKET.md`
- Frontier comparison template: `docs/CLAUDE_HAIKU_STRICT_ROW_TEMPLATE.md`
- DocDrop pipeline plan: `docs/LOCAL_PRIVACY_DOC_ANALYSIS_PLAN.md`
- PPR Lane 2 case: `docs/PPR_OLLAMA_LANE2_CASE.md`
- DocDrop scripts: `scripts/chalet_run_question.py`,
  `scripts/orchestrate_summaries.py`, `scripts/final_synthesis.py`
- PPR strict surface: `domains/DemoAgents/PPR_Agent/ppr_ollama.py`
- PPR Lane 2 evidence runner: `scripts/ppr_lane2_evidence_run.py`
- PPR Lane 2 canonical probe set: `domains/DemoAgents/PPR_Agent/benchmark/queries/ppr_lane2_canonical_probes.json`
- Scheduled suppression check: `scripts/gemma4_suppression_regression.py`
- Matrix rerun runner: `scripts/gemma_protocol_matrix_rerun.py`
- Upstream issue tracking the original false read + correction follow-up:
  `google-deepmind/gemma#604`
- OpenClaw routing context: `docs/OPENCLAW_ROUTING_POLICY.md`,
  `docs/PHOENIX_WORK_ROUTER_SPEC.md` (Lane 2 = local-strict-protocol)
