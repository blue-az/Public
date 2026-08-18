# The Default Draft Is Too Deep

## Status

Stub. Measured 16 Aug 2026. Not frozen. Not UID-verified.

Companion numbers live on the public local-lane note:
https://bulkheadtau.com/bulkhead-tau/local-lane/qwen38/#mtp

## Working claim

Ollama's stock `qwen3.8:27b` already turns on multi-token prediction. The leftover speed is not "enable MTP." It is **how many tokens the head is allowed to draft**. On a 24 GB 3090 and on a 2025 Strix Halo, the stock depth of **4** is slower than **2**. The vendor default copied the separate-draft-model convention. It is the wrong depth for this card class.

## The fix

Same Q4_K_M blob. Do not pull the Ollama library `:27b-mtp-` tag (a same-weekend report had that path 2× slower). Derive the stock tag and set:

```
PARAMETER draft_num_predict 2
```

Serve as `qwen38-mtp-2`. Daily on both machines.

## The improvement

Method: Ollama 0.32.12/0.32.13, `think` off, temp 0.8, 128-token generations, cold load each, decode = `eval_count / eval_duration`.

### Desktop — RTX 3090 24 GB @ 320 W, ctx 16384, n=4, 100% GPU

| Tag | draft | tok/s | sd | vs draft 0 |
|---|---:|---:|---:|---|
| `qwen3.6:27b` | — | 37.5 | 0.55 | — |
| `qwen38-mtp-0` | 0 | 40.3 | 0.05 | 1.00 |
| `qwen3.8:27b` stock | 4 | 41.4 | 4.21 | +3% |
| `qwen38-mtp-4` | 4 | 42.5 | 3.68 | +5% |
| **`qwen38-mtp-2`** | **2** | **50.3** | 2.71 | **+25%** |

Split of the earlier "+20% vs 3.6" figure:

- weights only: 40.3 vs 37.5 (~+8%)
- MTP at depth 2: another +25% on 3.8
- stock depth 4: noisy, barely above off

vs `gemma4:26b` at 133 tok/s, 50.3 is still 0.38×. Seat does not move. Interactive 3.8 does.

### z13 — Ryzen AI MAX 390 / 8050S, ctx 8192 (16k OOMs), n=3, 100% GPU

AC plugged in. Governor was `powersave`/`balanced` — conservative versus the earlier 16.3 @ `performance`.

| Tag | draft | tok/s | vs draft 0 |
|---|---:|---:|---|
| `qwen38-mtp-0` | 0 | 13.0 | 1.00 |
| `qwen38-mtp-4` | 4 | 17.7 | +36% |
| **`qwen38-mtp-2`** | **2** | **21.4** | **+65%** |

Draft 2 is the first time 3.8 clears the ~20 tok/s "I am watching this" floor on this laptop.

## Likely cause

Not proven. Consistent with the traces and with the llama.cpp MTP table that appeared the same weekend.

1. **Acceptance decays with draft depth.** The head proposes n tokens; the main model verifies them in one pass. Rejected drafts waste the verify. Community 24 GB rows peak at `n-max 2`. Deeper drafts help code and hurt prose. Our stock-4 arms are the noisy ones (sd 3.7–4.2). The off arm is a flat line (sd 0.05). That is what a decaying hit-rate looks like when you average mixed short generations.

2. **The default is the other kind of speculation.** Ollama documents `draft_num_predict` as defaulting to 4 for *separate* draft models, and says embedded MTP tensors "require setting this parameter." Stock `qwen3.8:27b` ships with 4. That is a library convention, not a 3090 measurement. We did not choose it.

3. **Bandwidth-poor decode pays more for a good depth and loses more for a bad one.** z13's +65% at depth 2 versus the 3090's +25% is the same shape as the community APU/iGPU rows: MTP amortises a starved weight read. Depth 4 still loses to 2 on both of our machines, so the miss is not "MTP off." It is "one click too deep."

What would falsify (1): a paired run that logs draft acceptance, with depth 4 showing equal or higher acceptance and still losing tok/s. We did not collect acceptance. The next measurement is that log, not another Elo cell.

## What this does not say

- It does not say 3.8 is more correct than 3.6. The seat battery is still a wash.
- It does not say 3.8 becomes the 3090 seat. 26b remains ~3×.
- It does not say llama.cpp would match these Ollama numbers. Different serve.
- It does not say depth 2 is universal. A 5090-class card in the community table peaks deeper. Measure the card you own.

## Open

- Log draft acceptance at 0/2/4 on both machines.
- Repeat z13 at `performance` (this stub's z13 arm was balanced/powersave).
- Do not use this as a ranking paper. It is a serve-parameter paper.

---

## Addendum — 18 Aug 2026: depth 2 is right at empty KV, depth 8 is right under load

The stub above stands as measured. A follow-up of 448 generations on the 3090 answers both of its Open items and changes the daily recommendation for one condition it did not sample: **occupied context**.

### The Open item is closed: acceptance was logged

`llama-server` reports per-position acceptance at INFO level (`#acc rate/pos`, `#mean acc len`). Mean accepted length rises monotonically with depth:

| draft depth | 1 | 2 | 4 | 6 | 8 |
|---|---:|---:|---:|---:|---:|
| mean accepted length | 1.88 | 2.56 | 3.53 | 4.05 | 4.13 |

### The stated falsification test fired

The stub asked for "a paired run that logs draft acceptance, with depth 4 showing equal or higher acceptance and still losing tok/s." That is exactly what depth **6** does: it accepts more per pass than depth 4 (4.05 vs 3.53) and is 11% slower (46.07 vs 51.99 tok/s at 45k context, t = −12.03).

**So hypothesis (1) — "acceptance decays with draft depth" — is not the mechanism.** Acceptance does not decay with depth; it rises. The cost is in the draft generation pass itself. No working mechanism has replaced it.

### Allocated context is not occupied context

This stub's protocol runs 128-token generations from a short prompt at `num_ctx 16384`. That **allocates** a 16k window the model never **occupies** — KV residency during those runs is near zero. Re-measured under this stub's exact protocol (temp 0.8, 128 tokens, think off, cold load, n=4):

| tag | draft | tok/s | sd |
|---|---:|---:|---:|
| `qwen38-mtp-0` | 0 | 40.67 | 0.19 |
| **`qwen38-mtp-2`** | **2** | **58.05** | 3.06 |
| `qwen3.8:27b` stock | 4 | 50.20 | 2.63 |
| `qwen38-mtp-4` | 4 | 50.86 | 4.05 |
| `qwen38-mtp-8` | 8 | 53.39 | 3.68 |

`mtp-0` reproduces the stub's 40.3 at 40.67. **Depth 2 wins at empty KV, as the stub says.**

### Under real occupied context, depth 8 wins

Seven content corpora (Rust, Python, prose, agent scrollback, mixed, CSV, journald logs), 400-token generations, fixed seed:

| draft depth | 15k ctx | 30k ctx | 45k ctx |
|---|---:|---:|---:|
| 2 | 57.50 | 52.82 | 49.80 |
| 4 | 56.52 | 52.70 | 51.99 |
| **8** | **65.04** | **57.89** | **52.53** |
| 12 | 58.99 | 52.62 | 30.92 |
| 16 | 29.10 | 8.26 | 5.88 |

Depth 8 beats stock by +8.52 tok/s at 15k (t = 3.33) and +5.19 at 30k (t = 2.48). **The stub stopped one power of two early.**

### Revised guidance

- **Short prompts, interactive one-liners:** depth 2, as published.
- **Loaded context — agent sessions, long files, anything past ~10k:** depth 8.
- **Never exceed 8.** Depth 12 is break-even with no speculation at 45k; depth 16 is ~5× *worse* than no speculation at every context length.
- **Only powers of two.** Depths 5, 6, 7 are all worse than both 4 and 8; 7 is worse than 6.

### One correction

The stub says "deeper drafts help code and hurt prose." Across seven corpora the split does not follow that line: Rust prefers depth 2 at every context length, while Python, prose, scrollback, logs and CSV all prefer deeper. Rust is the only one of seven that wants shallow drafts. "Code" is not the category.

Full study, 448 generations: `MTP_SPECULATIVE_DECODING_STUDY_2026-08-17.md`.
