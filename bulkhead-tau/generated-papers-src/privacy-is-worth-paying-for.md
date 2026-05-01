# Privacy Is Worth Paying For

## Status

Frozen and published (as of 2026-05-01).

This is a published paper, promoted from active draft following the capture of
the 2026-04-30 PPR evidence packet and the 2026-05-01 DocDrop same-task
frontier comparison ledger.

PPR evidence packet: `docs/PRIVACY_IS_WORTH_PAYING_FOR_PACKET_2026-04-30.md`

DocDrop same-task ledger: `docs/domain_runs/PRIVACY-DOCDROP-001/comparison_report.md`

It is the third frozen companion line in the local-LLM operator-judgment cluster:

- `GEMMA_4_IS_SMARTER_GEMMA_3_IS_SAFER.md` — handoff-discipline
  doctrine; model-behavior conflation
- `SLOW_IS_NOT_SMART.md` — size / quality conflation
- `PLEASE_IS_SAND_OFF_A_BEACH.md` — token-cost attribution; ritual-vs-structural waste conflation
- this paper — cost / privacy conflation

The lines share evidence (DocDrop, PPR Lane 2, the protocol matrix,
the suppression-regression probe) but make distinct claims.

## Measured Claim

The narrow form:

- privacy is the load-bearing reason to deploy DocDrop-class workloads on
  a local LLM
- our measurements on PPR Lane 2 show the local lane pays a **2.0× retry penalty** and requires massive prompt ritual overhead compared to a frontier equivalent
- our synthetic DocDrop same-task ledger shows the local lane at **1 / 3**
  first-pass success versus **3 / 3** for the frontier lane, with **1.83×**
  total-token use, **3.37×** output-token use, and **2.45×** wall-time
- the resource cost of local deployment is real and is rightly paid for the
  privacy benefit
- the resource cost is not avoided by relabeling the local lane as "free"

The broader form, and why this paper exists:

- the local-LLM market sometimes treats "no API charge" as equivalent to
  "no cost"
- under careful accounting, the same task uses materially more tokens,
  more GPU-seconds, more retry budget, and more operator wall-time on a
  local lane than on a frontier API
- the privacy benefit can absorb that cost honestly; the "free" framing
  cannot

The honest deployment case is "privacy is worth paying for," not
"privacy is free."

## Why This Paper Exists

The DocDrop privacy lane is currently the cleanest production-shape
privacy deployment in Project Phoenix. Its design is correct: local
inference on `localhost`, no API egress, sensitive documents on
operator-controlled media, strict 5-field JSON contract, schema
validation at the receive boundary.

The privacy argument for that design is bulletproof and survives any
accounting.

The trouble is that the privacy argument and a "no cost" argument get
bundled in operator framing — both for DocDrop specifically and for
local-LLM offloading more generally. Bundling weakens the privacy
argument because the "free" half does not survive scrutiny. Separating
the two strengthens the privacy half.

This paper exists to keep the two arguments separate, and to make the
cost ledger explicit so the privacy-vs-cost trade is a deliberate
operator choice, not a hidden one.

## How We Arrived Here

### 1. The DocDrop privacy lane is real

DocDrop processes sensitive meeting documents on USB media without data
egress. All inference is local Ollama on `127.0.0.1:11434`. The
deterministic boundary is preserved end-to-end. Pipeline run and
verified against real documents. The privacy benefit is unambiguous and
not in dispute.

### 2. The same task, two ledgers

A frontier model with native function-calling can typically extract the
DocDrop 5-field schema from a single document in a few hundred input +
output tokens, often on first pass.

The same task on `gemma4:26b` `/no_think` with `format: "json"` and a
strict receive-side validator costs more tokens for several structural
reasons (see next section), with the multiplier varying by document and
retry rate.

The frontier path costs cents per document at the API boundary. The
local path costs zero at the API boundary. That is the only place the
ledgers are even close to symmetric.

### 3. The two reasons get bundled

Operators choosing local for DocDrop-class work usually have at least one
of these in mind:

1. privacy: the data must not cross a privacy boundary
2. compliance / contractual: the data is not allowed to leave a tenant
3. cost: API charges are not in the budget
4. offline / availability: no reliable network path to a frontier API
5. control: the operator wants to own the inference path end-to-end

Reasons 1, 2, and 4 are clean and survive any cost analysis. Reason 3 is
the one that gets confused with "free" — and is the one this paper line
is about.

## Where the Cost Actually Shows Up

The local lane is not free at the resource level. The cost lives in
several places that an API-boundary view misses.

### Per-call structural overhead

- the schema must be in the prompt every single call; a frontier model
  with native function-calling skips that text entirely
- larger system prompts to compensate for lower instruction-following
- verbose reasoning preambles must be suppressed (`/no_think`) and
  monitored (the suppression-regression probe Project Phoenix built);
  even when suppressed, the suppression contract has to be tested
  on a schedule

### Retry amplification

- failed JSON parse and failed schema both cost full re-runs
- a 5% schema-failure rate over a 100-document batch is 5 extra calls
- the receive-side strict validator catches these correctly — but every
  catch is a paid retry

### GPU and wall-time

- decoding tokens locally costs GPU-seconds; for a 26B-class model at
  consumer hardware speeds, a long extraction can take 30+ seconds
- the operator waits for those seconds; "free" has no line item for
  operator wall-time
- power draw is not free

### Operator-side overhead

- prompt design and maintenance (longer, more constrained prompts than
  a frontier path needs)
- regression scaffolding (the probes Project Phoenix has scaffolded for
  exactly this reason)
- drift handling (catching upstream changes to Ollama or model weights
  that break the suppression contract)
- the choice to deploy a local lane is a choice to take on these
  obligations

### Capex

- the 32GB+ unified-memory hardware that runs a 26B-class model fluently
  is real money — see `SLOW_IS_NOT_SMART.md`

## Where the Trade Is Right

Local lane is the right deployment when privacy or availability
constraints are real and load-bearing:

- the data cannot cross a privacy boundary (DocDrop)
- the data is not allowed to leave the tenant
- the operator must run offline or in an air-gapped environment
- the operator has a hard budget constraint that closes the API path
- the workload is small enough that capex and ops time are dominated by
  the privacy benefit

In any of these cases, the resource cost is the cost of doing it right.
The claim is not "do not deploy local." The claim is "deploy local because
of privacy, not because of free."

## Where the Trade Is Suspect

When the privacy argument does not apply — work that is not sensitive,
data the operator is allowed to send to a frontier API, batch sizes
where API spend would be trivial — the cost case has to stand on its
own merits.

In those cases, "use local because it is free" often does not survive a
real volume × cost-per-call vs. capex + ops-time accounting. The
honest framing is that the operator is paying with hardware, electricity,
and wall-time instead of with API tokens. That can still be the right
choice, but it is not free.

The paper does not need to moralize about this. The corrective is just
making the ledger visible.

## Evidence 1: PPR Lane 2

The PPR Lane 2 packet measured a bounded tool-dispatch task on local
`gemma4:26b` versus a frontier-native function-calling lane. The headline is
not subtle: the local lane paid a **2.0x retry penalty** and carried much more
prompt-maintenance overhead to preserve strict machine-facing behavior.

That does not make the local lane wrong. It makes the deployment reason matter.
If the task is privacy-bounded, offline, or contractually restricted, the
extra cost may be justified. If the task is ordinary non-sensitive dispatch,
the local lane has to win on some other ledger.

## Evidence 2: DocDrop Same-Task Ledger

DocDrop is the stronger privacy exhibit because the real production lane is
privacy-bounded by design. Sensitive documents remain local. The frontier
comparison therefore uses synthetic `.docx` fixtures only, while the local lane
uses the same synthetic fixtures for apples-to-apples measurement.

The 2026-05-01 ledger compared:

| Lane | Model | Success | Input tok | Output tok | Total tok | Wall (s) |
|---|---|---:|---:|---:|---:|---:|
| local | `gemma4:26b` | 1 / 3 | 1502 | 2553 | 4055 | 25.083 |
| frontier | `gemini-2.5-flash` | 3 / 3 | 1460 | 757 | 2217 | 10.224 |

The local lane used:

- **1.83x** total tokens
- **3.37x** output tokens
- **2.45x** wall-time
- and failed two of three first-pass validations (`schema_fail`, `parse_fail`)

The frontier lane succeeded on all three documents. That is exactly why the
privacy argument must stand on privacy, not on an inherited claim that local is
cheaper or simpler.

## Evidence 3: Operator-Side Overhead

The accounting does not stop at tokens. The local lane also requires:

- prompt design and maintenance
- suppression-contract testing (`/no_think` must keep doing what the lane
  depends on)
- receive-side validators
- regression probes
- drift handling when model, runtime, or transport behavior changes
- hardware capacity and operator time

Project Phoenix treats those obligations as engineering work, not as hidden
externalities. That is the point: privacy can justify the local lane, but it
does not erase the cost of operating it.

## Boundary

This paper does not argue against local LLM deployment. It argues against the
wrong justification for local LLM deployment.

The correct argument for DocDrop is:

- the data is sensitive
- the privacy boundary is load-bearing
- local inference preserves that boundary
- the extra cost is the cost of doing the work correctly

The incorrect argument is:

- local inference has no API bill
- therefore local inference is free
- therefore local is the obvious default

That chain fails under measurement.

## Frozen Claim

Privacy is worth paying for.

That is stronger, more honest, and more durable than saying privacy is free.
