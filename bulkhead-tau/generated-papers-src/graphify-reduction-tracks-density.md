# Graphify's Reduction Ratio Tracks Graph Density, Not Code Quality

**Status:** active draft
**Date:** 2026-07-20
**Project:** Project Phoenix / Bulkhead Tau
**Publication posture:** paper-grade draft. Both falsification rounds and
both predictive tests are complete; the functional form of the
density-reduction relationship is not yet fit to anything and is stated as
an open question, not a finding.

## Abstract

`graphify` is a code-graph tool that scopes an AI assistant's context to a
single node's neighborhood instead of a whole repository, reporting a
token-reduction ratio for that scoping. The natural reading of a high or
low ratio is that it says something about the codebase — that a low ratio
means a monolithic file needing decomposition, or that a high ratio means
a well-factored one. Neither reading survived contact with a real
contrasting corpus.

This paper reports five rounds of measurement against six real codebases.
The first hypothesis — low ratio flags a monolithic file — was proposed
from one corpus and falsified by a second, genuinely modular one that
scored almost identically. The second hypothesis — the ratio tracks raw
graph size — fit three points cleanly and was falsified by a fourth,
smaller corpus that produced the highest ratio measured. The third
hypothesis — the ratio tracks graph density (edges per node), inversely —
fit all four points retrospectively, was confirmed by an exact independent
reproduction of a previously reported-only number, and was then tested
predictively twice: once on a corpus later retracted for uncertain
provenance, once on a corpus chosen specifically because its author could
vouch for it. Both predictions were directionally correct. The second one
missed its predicted magnitude by roughly 5x, which is itself informative:
it suggests the true relationship is closer to a power law than the
roughly linear shape the first four points implied, a question this paper
leaves open rather than answers.

A secondary and unplanned finding came from the process itself: a
predictive corpus was chosen, run, and written up as flagship evidence
before its provenance was checked, and only caught because the paper's
author flagged an unfamiliar codebase in the results. That correction — a
falsification loop catching its own methodology, not just its hypotheses —
is reported here as a first-class part of the result, not edited away.

## 1. Question

The motivating question:

> Does `graphify`'s reported token-reduction ratio measure something about
> a codebase's quality or structure — or does it measure something else
> entirely?

The naive answer is that it measures quality: a tool built to compress
context by exploiting modular structure should reward codebases that have
more of that structure to exploit. A low ratio would then be a legitimate
"this file needs splitting" signal, and a high ratio a legitimate "this is
well-factored" signal.

The measured answer is that it measures neither reliably. It measures
graph density — a real, mechanistically sensible property, but one that
correlates with modularity and code quality only loosely, and that can be
driven low by a single large file or high by a scattered collection of
independent scripts regardless of whether either is "good" code.

## 2. Method

The tool is `Evaluation/graphify_compare.py`, a loose utility script (not
part of any tracked repo) that wraps the `graphify` library
(`pip install graphifyy`, pinned at `0.9.22` for every run in this paper).
It performs one real graph load per run and calls `analyze.god_nodes()`,
`benchmark.run_benchmark()`, and `serve._find_node()` directly against the
library — it does not scrape CLI stdout, and this was confirmed by reading
the script before trusting any of its output.

Every run in the "independently run/re-run" column below was executed in
an isolated Python venv (`python3 -m venv`, `pip install graphifyy
networkx`) separate from any project venv, with numbers read directly off
the generated HTML/JSON output — never copied from a prior report. Rows
marked "reported only" were not independently verified at the time and are
labeled as such throughout.

## 3. Measurement Path

The important methodological fact is that the working hypothesis changed
three times, and each change came from running the tool against a new
corpus, not from reasoning about it in advance.

```text
modularity hypothesis -> falsified by ppr-agent
size hypothesis       -> fit n=3, falsified by YieldModel
density hypothesis    -> fit n=4 retrospectively, confirmed by exact re-run
                       -> predicted correctly on Algos (retracted: provenance)
                       -> predicted direction correctly on Sensors/ (magnitude missed 5x)
```

### 3.1 Modularity (falsified)

The first run, `operator-control-plane` — `Evaluation/operator` and its
supporting specs/tests/scripts, scoped per `Evaluation/CLAUDE.md`'s own
definition of the control plane — produced 183 nodes, 449 edges, 3.1x
reduction. `operator` is a single ~4,700-line file, so the natural reading
was that a low ratio reflects a lack of module boundaries to exploit.

`ppr-agent` — a genuinely modular codebase (9 files across 4 directories,
largest file 730 lines, the substrate behind Paper 1.18) — was run as the
contrasting test the modularity hypothesis needed. It scored 3.6x: barely
above `operator`'s ratio, not the high ratio a modular codebase should
have produced if modularity were the driver.

### 3.2 Size (falsified)

With the modularity story broken, the three points collected so far
(operator 180 nodes/3.1x, ppr-agent 271 nodes/3.6x, `graphify/extractors/`
424 nodes/5.8x, reported only) tracked node count monotonically. `YieldModel`
— an 18-file, 8-directory codebase unrelated to either `graphify` or
`operator` — was run as the test this hypothesis needed: a corpus with
fewer nodes than any prior run. It produced 150 nodes and 7.2x reduction —
the highest ratio measured to that point, on the smallest graph. Node
count does not explain the data.

### 3.3 Density (fit retrospectively, then confirmed, then predicted)

Graph density — edges divided by nodes — fit the three points that had
edge counts (`operator` 2.48/3.1x, `ppr-agent` 1.82/3.6x, `YieldModel`
1.42/7.2x), inversely and monotonically. The `graphify/extractors/` row
had been reported-only since the first round; independently re-running it
from the installed `graphifyy==0.9.22` package's own source reproduced the
originally reported numbers exactly (424 nodes, 5.8x, `_read_text()` at
degree 71 — no gap, unlike `operator-control-plane`'s small unresolved
one) and supplied the missing edge count: 733, density 1.73. That point
slotted in cleanly between `ppr-agent` and `YieldModel` on the same curve,
confirming density retrospectively at n=4.

A retrospective fit is weaker evidence than a prediction. `Algos/` — an
8-file collection whose imports were grepped before graphify ran and found
to have zero local cross-file references anywhere — was predicted, in
writing, before running: lower density and higher reduction than
`YieldModel`. It landed at density 0.99 (lowest measured) and reduction
14.4x (highest measured), extending the curve rather than breaking it.

### 3.4 The provenance correction

`Algos/` was chosen for its structural property alone. Its provenance was
not checked before it became the paper's flagship predictive evidence.
When the results were reviewed, the author of this codebase flagged
`Algos/` as unfamiliar — an empty sibling directory named
`hopcroft-dfa-erik-600c` matches a downloaded coding-assessment submission
naming pattern (problem name / username / hash), and the accompanying
README reads as generically templated rather than personally authored.

The measurement itself was not in question — the numbers were real and
independently produced. What was in question was whether a corpus of
uncertain, possibly non-representative origin should anchor a stub's
central predictive claim. It should not, and this paper retracts `Algos/`
as flagship evidence while keeping its numbers in the record. The lesson —
check a corpus's provenance before choosing it, not after being asked to —
is recorded here as a first-class part of the method, not an embarrassing
footnote removed from the final draft.

### 3.5 A harder, replacement prediction

`Sensors/ZeppU` — real personal tennis and golf sensor-analysis code —
was chosen as the replacement specifically because its author could vouch
for it. Its structure was read before running: every `main.py` in seven
subdirectories imports its own sibling `wrangle.py`; none cross
subdirectories. That is real coupling, unlike `Algos/`'s zero, but
fragmented into small isolated pairs — a harder, mid-range prediction than
`Algos/`'s extreme one. The prediction, stated before running: density
between `Algos` (0.99) and `YieldModel` (1.42); reduction between
`YieldModel` (7.2x) and `Algos` (14.4x).

`ZeppU` alone produced a graph too small for `graphify` to find a god node
at all — 21 nodes, 7 edges, and an outright error rather than a number.
This is a real negative result: `graphify`'s benchmark step appears to
need a minimum amount of code structure to function, and short, flat,
procedural data-wrangling scripts can fall under that floor. The scope was
widened to the whole `Sensors/` tree (36 files across six sibling sensor
projects, same "many small independent modules" character, more code
mass): 66 nodes, 38 edges.

Density landed at 0.58 — sparser than predicted, correct direction,
extending the record. Reduction landed at 72.1x — also correct direction,
but roughly 5x past the top of the predicted 7–14x range. The relationship
survived a second predictive test in direction. It did not survive in
magnitude, and that gap is the paper's most interesting open finding: a
comparatively small drop in density (0.99 to 0.58) produced a
disproportionately large jump in reduction (14.4x to 72.1x), which reads
as evidence for a non-linear, plausibly power-law-shaped relationship
rather than the roughly linear one the first four points suggested.

## 4. Results

| Corpus | Nodes | Edges | Density (e/n) | Reduction | Evidence status |
|---|---:|---:|---:|---:|---|
| Sensors/ (widened from ZeppU) | 66 | 38 | 0.58 | 72.1x | Predicted direction correct, magnitude exceeded prediction |
| Algos | 104 | 103 | 0.99 | 14.4x | Predicted correctly, retracted as flagship — uncertain provenance |
| YieldModel | 150 | 213 | 1.42 | 7.2x | Independently run |
| graphify/extractors/ | 424 | 733 | 1.73 | 5.8x | Independently run, exact match to reported |
| ppr-agent | 271 | 492 | 1.82 | 3.6x | Independently run |
| operator-control-plane | 180 | 446 | 2.48 | 3.1x | Independently re-run, small unresolved gap vs. reported |

All six order monotonically by density, including the retracted `Algos`
row. God nodes across the six runs: `serve_hist()` (a real rendering
function), `hopcroft_minimize()` (a real, on-topic algorithm function),
`render_era()` (a real, specific report function), `_read_text()` (a real
low-level utility, informative in its own right as a god node), `PlanBuilder`
(a real core class), and `TestOperatorCLI` (a test class outranking
`operator`'s own entry point — the one case where the auto-picked
"explain" target was arguably the wrong thing to surface by default).

## 5. Findings

### Finding 1: Two Intuitive Hypotheses, Two Falsifications

Modularity and raw node count both looked like clean, sufficient
explanations when tested against fewer than four corpora each. Both broke
immediately against a real, deliberately chosen contrasting corpus. A
hypothesis that fits every point it has been shown is not evidence of
correctness; it is evidence that not enough contrasting points have been
tried yet.

### Finding 2: Density Direction Confirmed Twice, Magnitude Confirmed Once

Density predicted the correct direction on two separate corpora chosen in
advance for a specific structural property, not selected after seeing a
result. On the harder of the two predictions (`Sensors/`, a mid-range
target rather than an extreme one), the direction held but the magnitude
missed by roughly 5x — evidence the relationship is real but its exact
shape is not yet known.

### Finding 3: A Codebase Too Sparse to Analyze Is a Real Failure Mode

`Sensors/ZeppU` alone produced no god node and no benchmark number at all.
Short, flat, function-poor procedural scripts can fall under whatever
minimum-structure threshold `graphify`'s benchmark step requires. This is
useful operational knowledge independent of the density question: pointing
`graphify` at a small, script-heavy directory may fail outright rather than
report a low but valid number.

### Finding 4: Evidence Provenance Is Part of the Measurement, Not a Footnote

A predictive corpus was run, written up, and treated as the paper's
strongest evidence before its origin was checked. The correction — flagged
by the paper's own author reviewing the result, not caught by any
automated check — is preserved in this paper rather than quietly edited
out. A falsification loop that only ever falsifies its hypotheses and
never its own procedural shortcuts is missing half the discipline it's
supposed to have.

## 6. Proof Boundary

This paper supports:

> `graphify`'s reduction ratio correlates with graph density (edges per
> node), inversely, confirmed by two independent advance predictions on
> two different real codebases — one later retracted from flagship status
> for provenance reasons, one confirmed in direction on a codebase the
> author could vouch for.

It does not show:

- the exact functional form of the density-reduction relationship (linear,
  power-law, or otherwise) — six points establish monotonic ordering, not
  a fitted curve
- that density is the *only* variable that matters — confounds with
  language, file-length distribution, or `graphify`'s own extraction
  heuristics have not been ruled out
- that `graphify/extractors/`, being the tool's own source, is a neutral
  comparison point even after independent confirmation
- that the minimum-structure floor `Sensors/ZeppU` fell under is
  reproducible or well-characterized — it happened once
- that this generalizes beyond the six codebases measured, five of them
  Python, all from one operator's personal and professional repositories

It does show:

- two prior, intuitive hypotheses (modularity, raw size) both failed real
  falsification tests
- density held direction across both predictive tests attempted
- an exact independent reproduction of a previously unverified number
  (`graphify/extractors/`, 424/5.8x/degree 71, no gap)
- a real negative result (`Sensors/ZeppU` alone, too sparse to analyze)
- a documented, self-caught provenance error in the measurement process
  itself

## 7. Reproducibility Notes

Primary local artifacts:

- `docs/GRAPHIFY_REDUCTION_TRACKS_DENSITY.md` (this paper)
- `Evaluation/graphify_compare.py` (the tool)

```bash
# isolated verification venv
python3 -m venv /tmp/graphify_verify_venv
/tmp/graphify_verify_venv/bin/pip install graphifyy networkx  # graphifyy==0.9.22 at time of writing

cd /home/blueaz/Python/Evaluation
/tmp/graphify_verify_venv/bin/python3 graphify_compare.py \
  --files operator EXECUTOR_IDENTITY_SPEC.md USAGE_AUTOIMPORT_SPEC.md VERIFIED_BY_GUARD_SPEC.md \
    tests enforce_identity_setup.sh enforce_workspace_permissions.sh run_dbb_benchmark.sh run_validators_DBB001a.sh \
  --base /home/blueaz/Python/Evaluation --label operator-control-plane

cd /home/blueaz/Python/ppr-agent
/tmp/graphify_verify_venv/bin/python3 /home/blueaz/Python/Evaluation/graphify_compare.py \
  --files charter core desk tests --base /home/blueaz/Python/ppr-agent --label ppr-agent

/tmp/graphify_verify_venv/bin/python3 /home/blueaz/Python/Evaluation/graphify_compare.py \
  /home/blueaz/Python/YieldModel --label yieldmodel

/tmp/graphify_verify_venv/bin/python3 /home/blueaz/Python/Evaluation/graphify_compare.py \
  /tmp/graphify_verify_venv/lib/python3.13/site-packages/graphify/extractors --label graphify-extractors

# retracted flagship (provenance uncertain) -- kept for completeness, not re-recommended
/tmp/graphify_verify_venv/bin/python3 /home/blueaz/Python/Evaluation/graphify_compare.py \
  /home/blueaz/Python/Algos --label algos

# replacement predictive test -- ZeppU alone errors (too sparse), Sensors/ widened succeeds
/tmp/graphify_verify_venv/bin/python3 /home/blueaz/Python/Evaluation/graphify_compare.py \
  /home/blueaz/Python/Sensors/ZeppU --label zeppu   # -> error: no god node found

/tmp/graphify_verify_venv/bin/python3 /home/blueaz/Python/Evaluation/graphify_compare.py \
  /home/blueaz/Python/Sensors --label sensors
```

The next reproducibility artifact, if this line gets more investment, is a
third advance prediction that commits to a magnitude range rather than a
direction alone, and a rough functional-form fit (power law is the natural
first candidate) across the six density/reduction points now in hand.
