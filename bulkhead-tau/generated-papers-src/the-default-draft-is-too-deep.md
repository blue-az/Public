# The Default Draft Depth Is Wrong
## Multi-Token Prediction Depth on a 24 GB 3090 and a Strix Halo Laptop

**Status:** active draft
**Date:** 2026-09-27 (first measured 2026-08-16)
**Project:** Bulkhead τ / Bulkhead Tau
**Paper group:** Local LLM Operator Judgment (provisional)
**Publication posture:** public draft. Not frozen. Not UID-verified.

Published as a stub on 2026-08-16 under the title *The Default Draft Is Too
Deep*. The page URL is unchanged. The retitle is explained in *What changed
since the stub*.

## Abstract

Ollama's stock `qwen3.8:27b` already runs multi-token prediction (MTP) with a
draft depth of 4. Turning MTP on does not recover the remaining speed; choosing
the depth does. The stock depth of 4 is not the best setting in any condition
we measured on two machines.

- **RTX 3090, empty context:** depth 2 is fastest (58.1 tok/s vs 50.2 stock).
- **RTX 3090, occupied context from ~15k tokens:** depth 8 is fastest, +8.5
  tok/s over stock at 15k.
- **Ryzen AI MAX 390 laptop (z13):** depth 2 is never worse than depth 4, is
  steadier, and pulls ahead as output grows. Depth 8 is slower than no
  speculation at all.

The default carries over the convention for *separate* draft models, where 4 is
standard. It was not chosen for embedded MTP on this card class. The operator
rule is short: **set `draft_num_predict` explicitly, per machine and per
workload, and never above 8.**

## The Setting

Same Q4_K_M blob as the stock tag. Derive the stock tag and set:

```
PARAMETER draft_num_predict 2
```

served as `qwen38-mtp-2`, and likewise `qwen38-mtp-0/4/8`. Do not pull the
Ollama library `:27b-mtp-` tag; a same-weekend community report had that path
2x slower.

Ollama documents `draft_num_predict` as defaulting to 4 for separate draft
models and says embedded MTP tensors "require setting this parameter." Stock
`qwen3.8:27b` ships with 4. That value is a library convention, not a
measurement on this hardware.

## Results

### 3090, empty context

RTX 3090 24 GB, ctx 16384 allocated, 128-token generations from a short prompt,
`think` off, temp 0.8, cold load each run, n=4, 100% GPU. Re-measured 2026-08-18
under the protocol of the 2026-08-16 stub.

| tag | depth | tok/s | sd |
|---|---:|---:|---:|
| `qwen38-mtp-0` | 0 | 40.67 | 0.19 |
| **`qwen38-mtp-2`** | **2** | **58.05** | 3.06 |
| `qwen3.8:27b` stock | 4 | 50.20 | 2.63 |
| `qwen38-mtp-4` | 4 | 50.86 | 4.05 |
| `qwen38-mtp-8` | 8 | 53.39 | 3.68 |

The original stub run (Ollama 0.32.12/0.32.13, 320 W) gave 40.3 / 50.3 / 41.4
for depths 0 / 2 / stock-4. The ordering is the same; the depth-4 arms are the
noisy ones in both runs.

### 3090, occupied context

Seven content corpora (Rust, Python, prose, agent scrollback, mixed, CSV,
journald logs), 400-token generations, fixed seed; 448 generations in all.

| depth | 15k ctx | 30k ctx | 45k ctx |
|---:|---:|---:|---:|
| 2 | 57.50 | 52.82 | 49.80 |
| 4 | 56.52 | 52.70 | 51.99 |
| **8** | **65.04** | **57.89** | **52.53** |
| 12 | 58.99 | 52.62 | 30.92 |
| 16 | 29.10 | 8.26 | 5.88 |

Depth 8 beats stock by +8.52 tok/s at 15k (t = 3.33) and +5.19 at 30k
(t = 2.48). At 45k the lead is within noise. Depth 12 falls to break-even with
no speculation at 45k, and depth 16 is about 5x worse than no speculation at
every context length. Depths 5, 6 and 7 are all worse than both 4 and 8.

The split does not follow a code/prose line. Rust prefers depth 2 at every
context length; Python, prose, scrollback, logs and CSV all prefer deeper. Rust
is the one corpus of seven that wants shallow drafts.

### z13 (Ryzen AI MAX 390 / Radeon 8050S)

ctx 8192 (16k OOMs), `performance` governor, Ollama 0.32.12, cold load each run,
100% GPU, prompts recorded (`MTP-Z13-GOVERNOR-001`, `MTP-Z13-LONGCTX-001`; 81
runs).

| workload | depth 0 | depth 2 | depth 4 | depth 8 |
|---|---:|---:|---:|---:|
| prose, 128 tokens, n=6 | 13.0 | 22.6 (+74%) | 23.2 (+79%) | — |
| Rust, 128 tokens, n=6 | 13.0 | 25.7 (+99%) | 25.6 (+97%) | — |
| 1024-token output, n=3 | 12.7 | 23.5 (+86%) | 21.8 (+72%) | 9.5 (−25%) |
| ~7.2k-token prose context, n=3 | 12.3 | 22.4 (+82%) | 20.2 (+64%) | 10.2 (−17%) |
| ~7.4k-token Rust context, n=3 | 12.3 | 20.4 (+65%) | 20.2 (+64%) | 8.8 (−29%) |

- At 128 tokens depth 2 and depth 4 tie. Depth 2 has about half of depth 4's
  run-to-run spread on prose and about a third on Rust.
- With long output depth 2 leads (+86% vs +72%, no overlap across reps).
- **Depth 8 is slower than no speculation in every z13 workload.** The 3090's
  "depth 8 under load" result does not transfer: z13 cannot reach the context
  lengths where it applies, and below ~7.4k depth 8 is the worst setting.
- The governor does not matter. Balanced and `performance` give the same
  numbers on the same prompt.

At depth 2 z13 gains +74% to +99%, against the 3090's +25% (stub protocol) to
+43% (re-measure). MTP pays more on the bandwidth-poor machine.

## Mechanism: What Is and Is Not Established

The stub offered three candidate causes. One is now refuted, one stands as
documentation, and one is strengthened.

1. **"Acceptance decays with depth": refuted.** The `llama-server` backend that
   Ollama launches logs per-position acceptance. Mean accepted length *rises* with depth: 1.88, 2.56, 3.53, 4.05,
   4.13 for depths 1, 2, 4, 6, 8. The stub's own falsification test fired: depth
   6 accepts more per pass than depth 4 (4.05 vs 3.53) and is 11% slower (46.07
   vs 51.99 tok/s at 45k, t = −12.03). The cost is in generating the draft, not
   in rejecting it. **No mechanism has replaced it.**
2. **The default is the separate-draft convention: documented.** This explains
   why the default is 4. It does not explain why 4 is slow.
3. **Bandwidth-poor decode gains more from a good depth: strengthened.** The z13
   vs 3090 gap now rests on recorded, reproducible prompts and is wider than the
   stub reported.

The paper therefore makes an empirical claim about settings. It does not make a
causal claim about why deeper drafts cost what they do.

## Operator Guidance

| machine | workload | depth |
|---|---|---:|
| 24 GB 3090 | short prompts, interactive one-liners | 2 |
| 24 GB 3090 | loaded context (agent sessions, long files, past ~10k) | 8 |
| 24 GB 3090 | Rust-heavy context | 2 |
| z13 / Strix Halo | everything | 2 |
| any | — | never above 8; powers of two only |

A 5090-class card in the community table peaks deeper. Measure the card you own.

## What Changed Since the Stub

- **Title.** "Too deep" was right for the empty-context case the stub measured
  and wrong for occupied context on the 3090, where the best depth is *deeper*
  than the default. What holds everywhere is that 4 is not the right number.
- **z13 depth 2 over 4.** The stub's +65% vs +36% did not replicate at 128
  tokens; its 17.7 tok/s is below every recorded-prompt depth-4 run. The stub's
  z13 prompt was not recorded. The ordering returns with long output.
- **"Deeper drafts help code and hurt prose."** Wrong. Only Rust wants shallow
  drafts.
- **Mechanism (1)** is refuted (above).

## What This Does Not Say

- That 3.8 is more correct than 3.6. The seat battery is a wash.
- That 3.8 becomes the 3090 seat. `gemma4:26b` remains roughly 3x faster.
- That a standalone llama.cpp serve would match these numbers. Every table here
  ran through Ollama 0.32.x. The acceptance counters come from the
  `llama-server` backend that Ollama launches, read from its INFO log.
- That depth 2 or depth 8 is universal. This is a serve-parameter paper, not a
  model ranking.

## Before Freezing

- UID-verified review (op-* reviewer identity).
- Bring the occupied-context study into the repo (it currently lives in the
  operator's notes vault) so its tables can be checked from the record.
- A mechanism for the draft-generation cost, or an explicit statement in the
  frozen text that none was found.

## Provenance

- Stub, 2026-08-16, and its addenda: git history of
  `docs/THE_DEFAULT_DRAFT_IS_TOO_DEEP_STUB.md`.
- 448-generation occupied-context study:
  `MTP_SPECULATIVE_DECODING_STUDY_2026-08-17.md`, in the operator's private notes
  (not yet in this repo).
- z13 recorded-prompt runs: `docs/domain_runs/MTP-Z13-GOVERNOR-001/`,
  `docs/domain_runs/MTP-Z13-LONGCTX-001/`.
- Companion numbers: https://bulkheadtau.com/bulkhead-tau/local-lane/qwen38/#mtp
