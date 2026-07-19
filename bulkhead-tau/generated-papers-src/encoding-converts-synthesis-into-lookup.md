# Encoding Converts Architecture Recovery into Lookup
## Two Local Models, Two Methods, One Documented System
### White Paper 1.40 — July 2026

**Author:** blue-az
**Status:** Published
**Paper group:** Local LLM Operator Judgment
**Evidence packet:** `docs/domain_runs/ENC-FLOOR-PACK-001/`
**Predecessors:** `SLOW_IS_NOT_SMART.md`, `WHEN_LOCAL_LLM_CLUSTERS_DO_NOT_HELP.md`, `THE_NARRATION_SURFACE.md`

---

## Abstract

A multi-repo software system can be made legible to a small, local language
model — cheap enough to run on a laptop iGPU or a single consumer GPU —
by encoding its architecture as findable facts: a short glossary, a map of
component boundaries, and a document that states plainly what the system
is not. Under that condition, recovering "what is this system and how is
it organized" stops being an open-ended reasoning problem and becomes a
lookup problem.

We measured this on one real internal system across two independent runs:
a 31B model (`gemma4:31b`) recovering the map via a tool-using REPL with no
pre-injected documentation, and a 14B model (`qwen2.5-14b-24k`) recovering
it via a full documentation funnel pre-concatenated into the prompt. Both
runs correctly answered all five cold-start boundary questions; the 31B run
did so with two gaps that were fixed same-day with one-line documentation
additions, after which the 14B run — conducted after the fix — passed
those same probes cleanly.

**This paper states its own evidentiary limit plainly rather than
implying more than it has:** the 14B run is fully verified — model,
context window, exact prompt token count, and complete answer text all
exist as machine-produced artifacts. The 31B run's tool-use trace and
serving configuration (model identity, context window) are independently
verified from a systemd service log and an audit trail; its per-probe
*answer text* is not — no chat transcript exists on disk for that session,
and the pass/fail record for it rests on same-day notes written by the
person who watched the session live. The two runs are also not a
controlled comparison: model, context window, and funnel method all differ
between them simultaneously. Both limits are treated as first-class
findings here, not asterisks.

---

## 1. Claim

The common assumption is that recovering an unfamiliar codebase's
architecture is inherently a synthesis task — the reader has to infer
structure from scattered evidence. That assumption holds when the
architecture is not written down anywhere a reader (human or model) can
find it. It stops holding once the architecture *is* written down, in one
place, in a form a cheap reader can locate and parse.

The defended claim:

> Encoding a system's architecture as loadable repository facts — a
> vocabulary glossary, an entry-point map, a boundaries document, and
> explicit non-claims — converts cold-start architecture recovery from
> open-ended synthesis into documentation lookup. Local models that fail
> open-ended goal-shaped tasks can still answer correctly about
> boundaries, vocabulary, and trust rules, provided the funnel fits the
> context window and the method (tool-search vs. pre-injection) is held
> in mind when interpreting the result.

The claim is narrow on purpose. It is not a claim about local models
being broadly capable, and it is not a claim that any model recovers any
repository. It is a claim about what happens to a specific, bounded task
— cold-start map recovery — once the answer key exists in a locatable
form.

---

## 2. Method

Two runs, five identical probes, one real system (an internal project's
core module and its documented component boundaries):

1. **Vocabulary** — what is this system?
2. **Boundary** — what is its "lower boundary," its source of ground
   truth?
3. **Composition / trust rules** — how does a related tool fit into the
   system?
4. **Acronym recall** — what does the system's charter acronym stand for?
5. **Subsystem weighting** — how central is a named legacy technology to
   the system?

| Run | Model | Size | Machine | Method | Context window |
|---|---|---:|---|---|---:|
| A | `gemma4:31b` | 31B | desktop (RTX 3090-class) | Tool-using REPL — the model called `read_file`/`grep_search`/`list_dir`/`tree_dir` itself; no documentation was pre-injected | 32,768 tokens |
| B | `qwen2.5-14b-24k` | 14B | laptop (integrated GPU) | Static funnel — five documentation files pre-concatenated into the prompt | 24,576 tokens |

These two runs are not a controlled experiment. Model, context window, and
funnel method differ simultaneously. They are reported as two independent
positive measurements under two different methods, not as a single
"floor" located at one model size.

---

## 3. Evidence

### 3.1 Run A — Desktop, `gemma4:31b`, tool-using REPL

Run A asked a local agent, with no pre-loaded context beyond a system
prompt, to answer the five probes by searching the repository itself. The
model identity and serving context window are independently verified
against a systemd `ollama` service log (`journalctl -u ollama`), whose
model-load timestamp lines up to the second with the start of the
tool-call trace for this session. The tool-call sequence itself — which
files and search terms the REPL touched, in what order — is independently
verified against a mechanical tool-call audit log.

What is **not** independently verified: the model's generated answer text
for each probe. No chat transcript for this session exists on disk. The
pass/fail record below is sourced from same-day operator notes, not from a
re-readable artifact.

### 3.2 Run B — Laptop, `qwen2.5-14b-24k`, static funnel

Run B pre-concatenated five documentation files (91,927 characters) into a
single prompt and asked the same five questions via direct API calls,
recording `prompt_eval_count` on every response as proof the full funnel
fit inside the context window (measured 23,736–23,744 tokens against a
24,576-token window — roughly 800 tokens of headroom, comfortably
in-window). Both the exact prompt-token counts and the complete verbatim
answer text for all five probes exist as raw JSON on disk.

### 3.3 What is independently verified vs. narrated

| Fact | Status | Source |
|---|---|---|
| Run B: model, context window, prompt fit, exact answer text | Verified | Raw JSON with `prompt_eval_count` and full output text per probe |
| Run A: model identity and context window | Verified | Independent systemd service log, timestamp-matched to the tool-call log |
| Run A: which files/topics were searched, in what order | Verified | Independent tool-call audit log |
| Run A: exact answer text per probe | **Not verified — narration only** | Same-day operator notes; no transcript exists on disk |

This table is the paper's central honesty constraint. Any reading of this
paper that treats Run A's per-probe verdicts as equivalent in evidentiary
weight to Run B's is reading past what the evidence supports.

---

## 4. Probe-by-Probe Results and Gap Classes

| # | Probe | Run A (tool-search, 31B) | Run B (pre-injected, 14B) | Gap class if failed |
|---|---|---|---|---|
| 1 | What is the system? | Pass, with one register slip (a marketing pitch was read as architecture; fixed same day) | Pass, clean | register confusion |
| 2 | What is the lower boundary? | Pass | Pass | — (this probe also confirmed a fix to a pre-existing, unrelated documentation bug) |
| 3 | How does the related tool fit in? | Pass, complete | Pass, complete | — |
| 4 | What does the acronym stand for? | Correct role, wrong expansion, twice — fixed same day by adding the spelled-out term to the glossary | Pass, clean (run after the fix) | acronym confabulation |
| 5 | How central is the legacy subsystem? | No answer — files existed but were not linked from anywhere findable; fixed same day with a one-line lineage note | Pass, clean (run after the fix) | unlinked subsystem |

Every failure in this table was a **documentation gap, not a model
failure**: each was closed with a one- or two-line documentation addition,
and Run B — which ran after the fixes — passed those same probes cleanly.
This is the paper's operational finding: used this way, a local model
functions as a cheap, fast probe for finding where documentation is thin,
not merely as a system-recovery tool.

A sixth gap class predates both probe runs: a pre-existing documentation
bug had mislabeled one component's role, and an unrelated agent session
had already silently inherited the wrong answer days earlier. Probe 2 in
Run A is the same-day confirmation that correcting the document actually
corrected what the model reports — the same weights, a different repo
state, a different answer. This is the **taxonomy drift** gap class, and
it is the reason the probe exercise was run at all.

---

## 5. Invalid Controls

Two additional runs were reported and are explicitly excluded from the
result above, because each altered more than one variable at once or
never engaged the documentation:

| Control | Why it's invalid as a floor measurement | Evidence status |
|---|---|---|
| A laptop run on a different, smaller model at the software's stock (much smaller) context window | The documentation could not fit in the space given — failure there tests context truncation, not the encoding | Reported only; no raw artifact packaged |
| A chat-style interaction that answered from general world knowledge without any file access | Tests world knowledge, not documentation recovery — the funnel was never contacted | Reported only; no raw artifact packaged |

Neither control has a machine-produced log in this paper's evidence
packet. Both are recorded as reported claims, not independently confirmed
measurements, and are excluded from the result rather than counted as
either supporting or contradicting evidence.

---

## 6. Interpretation

Under this encoding, a **31B** tool-using agent and a **14B** model reading
a pre-injected funnel both recovered the documented architecture of one
real system. Neither run is, by itself, proof that "local models can
recover any repo's architecture." Together they show something narrower
and more useful: when the answer key exists in the repository in a
locatable form, cold-start recovery becomes a lookup task cheap enough for
models an order of magnitude smaller than frontier-class systems to
perform reliably — with the caveat that "reliably" here means "passed
after the same-day documentation fixes this exercise itself produced."

The failures that did occur (acronym confabulation, unlinked subsystem,
register confusion, taxonomy drift) form a small, recognizable taxonomy.
Each is a specific, nameable documentation gap rather than a diffuse
capability shortfall — which is itself evidence for the encoding claim:
if the model were simply "too weak," failures would look like confusion
across the board rather than four sharply distinct, individually
fixable gaps.

---

## 7. Boundaries and Non-Claims

This paper does not claim:

- Local models can replace the people who design or review this system.
- Any 14B (or any-size) model would recover the architecture map of *any*
  other software project — this is one system, deliberately documented
  for this purpose.
- The two runs are directly comparable performance data — model, context
  window, and funnel method all differ between them.
- Passing-with-a-fixable-gap and passing-clean are the same outcome —
  they are reported as distinct results throughout this paper.
- Run A's per-probe answers are independently reproducible — they are
  not; see §3.3.
- OpenWiki (or any other doc-chat tool) is validated as an evaluation
  harness by this paper — the OpenWiki-adjacent control in §5 is an
  invalid measurement, not a product endorsement or indictment.

It claims only what §1 states: for this system, under two named methods,
architecture recovery behaved as lookup rather than synthesis, and the
failures that did occur were documentation gaps with one-line fixes.

---

## 8. Practical Rule

Before treating a local model's cold-start read of a system as evidence
of anything beyond documentation quality, ask three questions in order:

1. Does the answer key exist in the repository in a form a cheap reader
   can find — not just in the maintainer's head or in scattered handoff
   files?
2. Does the funnel (whichever way it reaches the model — tool search or
   pre-injection) actually fit inside the context window in use?
3. Is the model's answer text itself independently verifiable, or does
   the record rest on someone's notes about what the model said?

For Run B in this paper, the answers were yes / yes / yes. For Run A,
they were yes / yes (after correction) / **no** on the third question —
and this paper says so in its abstract rather than its footnotes.

---

## 9. Reproducibility Commands

```bash
cat docs/domain_runs/ENC-FLOOR-PACK-001/working_note.md
cat docs/domain_runs/ENC-FLOOR-PACK-001/method_matrix.md
cat docs/domain_runs/ENC-FLOOR-PACK-001/invalid_controls.md
cat docs/domain_runs/ENC-FLOOR-PACK-001/promotion_packet.md

# Run A — desktop gemma4:31b opr tool-use trace and serving config
cat docs/domain_runs/ENC-FLOOR-PACK-001/desktop_gemma4_31b_opr_evidence.md
cat docs/domain_runs/ENC-FLOOR-PACK-001/desktop_gemma4_31b_opr_tool_audit.jsonl
cat docs/domain_runs/ENC-FLOOR-PACK-001/desktop_gemma4_31b_ollama_journal_excerpt.log

# Run B — z13 qwen2.5-14b-24k static funnel
cat docs/domain_runs/ENC-FLOOR-PACK-001/z13_static_funnel_raw.json
cat docs/domain_runs/ENC-FLOOR-PACK-001/z13_static_funnel_answer.md
python docs/domain_runs/ENC-FLOOR-PACK-001/bt_floor_probe_2026-07-18.py
```

Verify the key numeric claims:

```bash
grep -o '"prompt_eval_count": [0-9]*' docs/domain_runs/ENC-FLOOR-PACK-001/z13_static_funnel_raw.json
grep "n_ctx" docs/domain_runs/ENC-FLOOR-PACK-001/desktop_gemma4_31b_ollama_journal_excerpt.log
```

---

## 10. Conclusion

The finding worth keeping is narrower than "local models can read code."
It is: when a system's architecture is deliberately encoded as loadable,
findable facts, cold-start recovery of that architecture stops requiring
model-scale reasoning and starts rewarding documentation quality instead.
Two independently-methoded local models recovered this system's map under
that condition; the gaps that surfaced were documentation gaps, not model
failures, and each was closed in one line. The one place this paper
declines to overstate itself is Run A's answer text, which remains
narration-sourced — a limit reported here as plainly as the result itself.

> Write the system so the weakest useful reader can find the map. Then
> measure the floor — and say clearly which parts of that measurement you
> can still check tomorrow.
