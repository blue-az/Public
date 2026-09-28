# One Model Per Card Costs Nothing — One Card Is an Eviction Tax

**Status:** active draft
**Date:** 2026-09-27 (first measured 2026-08-27)
**Project:** Bulkhead τ / Bulkhead Tau
**Paper group:** Local LLM Operator Judgment (provisional)
**Publication posture:** public draft. Not frozen. Not UID-verified.

## Abstract

Two different local models served at the same time on two GPUs, one model per
card, do not slow each other down. Measured on two model pairs and two dual-3090
machines, one-per-card decode stays within about 6% of each model running alone
at up to four concurrent requests, and within noise at one or two.

Putting both models on one card that cannot hold them both costs a great deal.
The cost is not slower decoding. The card cannot batch across two different
models, so it swaps them, and every swap is a reload: **3x the wall clock for a
gemma pair and 5.4x for a qwen pair.** With one model already loaded and idle,
the swap can also fail to happen. The resident model serves its own requests,
the scheduler logs an eviction it does not perform, and the second model waits
until the first model's `keep_alive` expires: 158.9 s at a 2-minute keep_alive,
938.7 s at 15 minutes.

Whether a second GPU is needed for mixed-model serving is therefore a placement
question, not a capacity question. **Give each model its own card.**

## Setup

- **Hardware:** two dual-RTX-3090 machines. The desktop (2026-08-27, 320 W) ran
  the original measurement. The headless testbench (2026-09-27, 350 W) ran the
  follow-ups.
- **Pairs:** `gemma4:26b` (MoE, 17 GB) + `gemma4:31b` (dense, 19 GB), and
  `qwen2.5-coder:32b` (dense, 19.9 GB) + `qwen3.8:27b` (dense, 17.7 GB).
- **Serve:** one Ollama daemon per card, each gated to exactly one CUDA device
  on the expected PCI bus, and a per-cell placement gate (the model is on the
  intended card by `nvidia-smi` memory). Flash attention, q8_0 KV cache,
  ctx 8192, temp 0, 256-token generations, the MULTI-MODEL-SERVE-001 prompt.
- **Cells:** A = model 1 alone on its card; B = model 2 alone on its card;
  C = both, one per card; D = both on one card.
- **Metric:** per-request decode (`eval_count / eval_duration`) for
  interference; wall clock per request pair for the one-card cost. Aggregate
  tok/s across two models is not a throughput sum. It is bounded by whichever
  model finishes last, and it is not used for interference.

A pass without `OLLAMA_VULKAN=0` let each daemon see the other card through
Vulkan. It is kept in the packet, marked invalid, and not analysed.

## Results

### 1. One model per card: no interference

Change in per-request decode, cell C against the same model alone:

| pair | model | N=1 | N=2 | N=4 |
|---|---|---:|---:|---:|
| gemma, desktop, 2026-08-27 | 26b | +0.1% | — | — |
| gemma, desktop, 2026-08-27 | 31b | −1.9% | — | — |
| gemma, `NUM_PARALLEL=2` | 26b | +1% | −4% | — |
| gemma, `NUM_PARALLEL=2` | 31b | +0% | −1% | — |
| gemma, `NUM_PARALLEL=4` | 26b | −5% | −9% | −6% |
| gemma, `NUM_PARALLEL=4` | 31b | −0% | −2% | −4% |
| qwen, `NUM_PARALLEL=2` | 32b | −0% | −1% | — |
| qwen, `NUM_PARALLEL=2` | 27b | +5% | +3% | — |

The harness noise floor is about 1.5% typical and up to 3%. Under
`NUM_PARALLEL=4` 26b shows a small, consistent penalty (−5% to −9%) that n=3 per
cell cannot separate from noise.

### 2. Both on one card: the eviction tax

The two models cannot be co-resident on one 24 GB card. `/api/ps` shows one
loaded at a time, and each request for the other model reloads it.

| pair, config | one per card (C) | both on one card (D) | cost |
|---|---:|---:|---:|
| gemma, `NUM_PARALLEL=2` | 8.4 s | 25.2 s | **3.0x** |
| gemma, `NUM_PARALLEL=4` | 15.8 s | 33.5 s | 2.1x |
| qwen, `NUM_PARALLEL=2` | 7.3 s | 39.8 s | **5.4x** |

Wall clock is for one request to each model, N=1. Per-request decode in D is
nearly unchanged (gemma 26b −5% to −8%, 31b +3% to +5%, qwen 32b −0%). The one
exception, qwen3.8:27b at +18% in D, is n=3 and unexplained, and is not
interpreted. The cost
is reload: `load_duration` in D is 6.6–7.2 s for 31b and 15.7–21.2 s for 26b per
request, against 0.6 s in C.

How the card swaps depends on `NUM_PARALLEL`. At 4 it batches each model's
requests and swaps once. At 2 it thrashes, swapping more than once, and the last
of four requests finishes at 64–83 s.

### 3. Starvation from an idle resident model

On one card with 26b already loaded and idle, a burst of two 26b and two 31b
requests (`NUM_PARALLEL=4`):

| run | 26b requests | 31b requests | outcome |
|---|---:|---:|---|
| keep_alive 2m, rep 1 | 3.0 s | 38.7 s | normal swap |
| keep_alive 2m, rep 2 | 3.1 s | **158.9 s** | stall |
| keep_alive 15m, rep 1 | 3.1 s | **938.7 s** | stall |

In the 15-minute stall, 26b finished its requests at 21:41:35, which set its
expiry to 21:56:35. The scheduler had already logged "predicted to exceed
available memory, evicting", yet 26b stayed loaded and idle. The 31b requests
completed at 21:57:11: the expiry plus one ~20 s load. The 2-minute stall has
the same shape.

From this preloaded state the stall occurred 3 times in 4 tries, counting the
first, unplanned occurrence on the morning of 2026-09-27. From an empty card it
did not occur in any of 7 tries (6 with the gemma pair, 1 with the qwen pair),
at keep_alive 1m, 2m and 15m and at both `NUM_PARALLEL` settings. **A long keep_alive turns a request for the second
model into a wait of up to the keep_alive.** One model per card avoids it
entirely.

### 4. A residency cost of `NUM_PARALLEL` itself

At `NUM_PARALLEL=4`, 31b is 91.4% GPU-resident (59/61 layers) even alone on its
own card, because the daemon reserves KV cache for four 8192-token slots. Its
alone rate drops from 33.8 to 18.3 tok/s. This is a configuration cost, separate
from interference, and it only appears for a model near the card's capacity.

## What Is New Relative to Earlier Work

| study | configuration | established |
|---|---|---|
| DUAL-GPU-EXPANSION-001 (+ MATCHED-PAIR-001) | one model split across two cards | Splitting pays only in proportion to overflow; an unnecessary split on a matched pair is free (+1.6%). |
| DUAL-SERVE-001, corrected by CONCURRENCY-001 | the same model on both cards, requests split | A pinned pair beats one batching card by +33% to +52% (N=2–8); one card gains +144% from batching, N=1 to N=8. |
| **this paper** | **two different models** | Cross-model interference is measured and is zero within noise. One card cannot batch across different models, only swap, so its cost is reload (3x–5.4x). It can also starve the second model for up to its keep_alive. |

## The Debugging Trail Is Part of the Finding

The first measurement took three rounds of daemon debugging before it could be
trusted, and each wrong round would have produced a publishable-looking number:

1. A manually started second `ollama` daemon did not inherit the systemd unit's
   environment. Missing flash attention and KV-cache settings spilled 11 of 61
   `gemma4:31b` layers to CPU, at ~8 tok/s. That reads as "31b cannot serve
   concurrently."
2. Pinning `OLLAMA_CONTEXT_LENGTH` did not fix the rest of the spill. Reserved KV
   context is `NUM_PARALLEL` x per-request context, so the default of 4
   reserved 32k for a test that never sent more than two concurrent requests.
3. Matching `NUM_PARALLEL` to the run's real concurrency restored full
   residency.

The September testbench run found a fourth: without `OLLAMA_VULKAN=0`, a
CUDA-gated daemon can still reach the other card through Vulkan. **An
unexplained throughput number in a local-inference benchmark is at least as
likely to be a daemon-configuration artifact as a capacity or contention
finding.** Every cell in this paper passed both a backend gate and a placement
gate for that reason.

## Limits

- n=3 per cell for interference. The −5% to −9% on 26b at `NUM_PARALLEL=4` is
  unresolved.
- Two pairs, both 17–20 GB models on 24 GB cards. Small models that *can*
  co-reside on one card are a different case; see *Parameter Count Does Not Price
  the Card* for two mid-size models co-resident on a 48 GB pool.
- Starvation was observed only with the gemma pair at `NUM_PARALLEL=4`, on the
  testbench's installed Ollama. The preloaded state at `NUM_PARALLEL=2`, the qwen
  pair, and other Ollama versions are untested. It is intermittent (3 of 4), and
  what decides whether a given burst stalls is not known.
- The August desktop run and the September testbench runs differ in power limit
  (320 W vs 350 W) and in machine. They are compared by direction, not pooled.

## Before Freezing

- UID-verified review (op-* reviewer identity).
- Starvation from the preloaded state with the qwen pair and at
  `NUM_PARALLEL=2`, to bound its scope.
- A check against a current Ollama release, since the stall looks like
  scheduler behaviour that a version could change.

## Provenance

- Original measurement: `docs/domain_runs/MULTI-MODEL-SERVE-001/findings.md`
  (2026-08-27), `PLAN.md` (2026-08-23), and four timestamped evidence sets
  (three from the debugging trail, one clean).
- N=4, placement, second pair, starvation, cross-reference:
  `docs/domain_runs/ONE-MODEL-PER-CARD-N4-001/findings.md` and its evidence
  directories, including per-request JSON and daemon logs for each stall.
- Related: `docs/domain_runs/CONCURRENCY-001/findings.md`,
  `docs/domain_runs/DUAL-GPU-EXPANSION-001/`.
- Harness contract: `docs/LOCAL_INFERENCE_BENCH_HARNESS.md`.
- The stub this draft supersedes: git history of
  `docs/ONE_MODEL_PER_CARD_COSTS_NOTHING_STUB.md`.
