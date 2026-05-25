# The Model Is Not The Function

**Status:** frozen 2026-05-01

**Paper group:** Local LLM Operator Judgment

## Working Claim

Short code, simple code, fewer lines, fewer dependencies, and better systems
are often conflated. The same mistake now appears in LLM-runtime arguments:
a model call can make code look simpler while making the system less
deterministic, slower, more expensive, and harder to verify.

The claim is not that model calls are bad. The claim is narrower:

> For bounded predicates with deterministic oracles, an LLM must earn runtime
> use against a written spec, not against the visual length of the code it
> replaces.

## Why This Paper Exists

The common "coding in 2027" joke compares a tiny deterministic helper against
a large model-call wrapper. That is funny because it is partly true, but the
comparison may be measuring the wrong thing.

This is also an old argument about libraries and lines of code:

- importing a dependency for three lines can be waste, or it can be the right
  abstraction if it carries edge cases and maintenance value
- lines of code count within a stable context, but become noisy across
  programmers, languages, specs, and edge-case expectations
- shorter code is not automatically simpler systems code

## Scope and Non-Claims

This paper is narrow on purpose.

- **In scope:** bounded predicates with deterministic oracles, of the kind a competent engineer can specify in a paragraph (`startsWithCapitalLetter`, `isISODate`).
- **Sample size:** 20 fixtures (CAP-001) and 19 fixtures (LIB-001). First-evidence packets, not benchmarks.
- **Models tested:** local Ollama lanes — `llama3.1:8b` and `gemma4:26b`. Not frontier hosted models, not structured-output modes, not tool-augmented agents.
- **Not claimed:** that LLMs are bad at language tasks, that frontier models cannot pass these predicates, that agentic systems should avoid model calls, or that any unbounded natural-language task should be replaced by deterministic code.
- **Claimed:** for this class of task, "replace the function with a model call" must earn its runtime against a written spec — not against the visual length of the code.

## Synthesis of Evidence

The evidence from CAP-001 and LIB-001 demonstrates that for bounded predicates with deterministic oracles, raw model capability is an insufficient substitute for a well-defined specification or a standard library.

### 1. Raw Scale Does Not Solve Operational Cost (CAP-001)
In CAP-001 (`startsWithCapitalLetter`), we ran two LLM lanes against a spec-aware deterministic lane on 20 fixtures. The smaller model (`llama3.1:8b`) was fast but only reached 75% accuracy — it didn't solve the problem. The cheapest LLM lane that *did* match the spec-aware lane was `gemma4:26b` at 100% accuracy and ~45.6 s average wall time. The spec-aware deterministic lane finished all 20 fixtures in ~22 µs. The honest comparison is therefore between the spec-aware lane and the smallest LLM that actually meets the bar: a wall-time gap of roughly six orders of magnitude, on a predicate whose specification fits in a paragraph. Visual simplicity (a single model call) concealed an operational burden that scale did not pay down.

### 2. Standard Libraries Trump LLM Invocations (LIB-001)
In LIB-001 (`isISODate`), the argument sharpened. The Python standard library (`datetime.date.fromisoformat`) provided perfect accuracy at ~0.00007 s total wall time across 19 fixtures. The `gemma4:26b` lane yielded 19/19 parse failures — every response was an empty string. We re-ran the lane with the output-token cap raised from `num_predict=4` to `num_predict=64`; the empty-output result was unchanged, so this is not a token-cap clipping artifact. We do not claim every LLM runtime exhibits this failure mode; we claim that this specific prompt-and-model configuration emits zero usable answers, that it survives the obvious knob, and that the deterministic lane cannot fail this way by construction. Visual simplicity (a one-line model call) here purchased an operational lane that returned no answers at all.

## Conclusion

"Visual simplicity" in code (replacing logic with a model call) often conceals significant "system complexity" and operational risk. A deterministic, spec-aware function or a standard library call is not just faster and cheaper; it is fundamentally more governable, reliable, and predictable. The model is not the function; it is a probabilistic approximation of the function with a high-cost runtime.

---

## Evidence Ledger

- **CAP-001 (`startsWithCapitalLetter`):** `docs/domain_runs/CAP-001/report.md`
- **LIB-001 (`isISODate`):** `docs/domain_runs/LIB-001/report.md`
- **LIB-001 num_predict verification:** `docs/domain_runs/LIB-001/verify_num_predict_report.md` — confirms 19/19 empty-output reproduction and rules out the token-cap hypothesis (2026-05-01).
