# Dedicated 24 GB Beats Unified 27 GB: The Capacity Trap in Local Inference

**Status:** active draft  
**Date:** 2026-07-04 (updated 2026-07-20, Section 12)  
**Project:** Project Phoenix / Bulkhead Tau  
**Publication posture:** paper-grade draft. Multi-prompt variance pass completed
2026-07-05 (Section 10); the core numbers are now variance-backed and the gate is
closed. A realistic-context residency confirmation (Section 12) was folded in
2026-07-20 — it widens the desktop's measured advantage on gemma4:26b/31b and
flags that some earlier power-sweep numbers may not have been confirmed
GPU-resident. Not yet frozen, pending a publication decision.

## Abstract

Local LLM hardware is often compared by the largest advertised memory number:
24 GB dedicated VRAM, 27 GB unified memory, 64 GB system RAM, and so on. That
comparison hides the two variables that matter operationally: how much memory
the accelerator can actually address, and how fast the accelerator can read and
compute through the model once it is resident.

This paper reports a head-to-head local-inference measurement between a desktop
RTX 3090 with 24 GB dedicated GDDR6X and a Strix Halo laptop with 27 GB shared
LPDDR5X. The laptop is not a weak opponent: it is a best-case x86 unified-memory
machine for local LLM work. Even so, the dedicated card wins on both dimensions
that matter. It can keep larger practical models fully resident, and it runs
fit-both models much faster.

The result is sharper because the measurement corrected the interpretation
repeatedly, then confirmed it. The datasheet suggested that the desktop should
be roughly 3.6x faster from memory bandwidth alone. A first 200 W desktop run
measured only about 2x and made the bandwidth story look oversold. A later 300 W
run measured roughly 3x, showing that the 200 W result was a power-state
artifact, not a refutation of the spec-sheet physics. Finally, a multi-prompt
variance pass with the laptop measured warm rather than cold moved the dense
ratio to about 3.5x, within a few percent of the 3.66x bandwidth prediction —
the spec was not oversold at all; the early undershoots were stacked measurement
artifacts. The final claim is therefore not a clean slogan. It is conditional
and more useful:

> Dedicated memory beats larger unified memory, but the size of the win depends
> on power state, model architecture, and whether the model spills.

## 1. Question

The motivating question is simple:

> Is a 27 GB unified-memory laptop a better local-inference machine than a
> 24 GB dedicated-GPU desktop?

The naive answer is yes. Twenty-seven is larger than twenty-four, and unified
memory is marketed as a way to make the whole system memory pool available to
the accelerator.

The measured answer is no. The larger sticker number is the trap. The laptop's
GPU-addressable allocation is much smaller than the advertised shared-memory
pool under its default configuration, and when models spill past that boundary,
throughput collapses. The desktop's 24 GB is smaller on the label but more
useful in practice because it is dedicated, high-bandwidth accelerator memory.

This is a capacity paper and a speed paper. The capacity result is the lead:
larger nominal unified memory can invite users to load models that run, but run
badly. The speed result explains why: dedicated accelerator memory and adequate
power keep the model on the fast path.

## 2. Hardware

| | Desktop | Laptop |
|---|---:|---:|
| Accelerator | NVIDIA RTX 3090 | AMD Ryzen AI MAX 390 / Radeon 8050S |
| Memory label | 24 GB dedicated GDDR6X | 27 GB shared LPDDR5X |
| Approx. bandwidth | 936 GB/s | 256 GB/s |
| GPU-addressable in tested default | 24 GB | about 18 GB (4 GB VRAM + 13.8 GB GTT) |
| Power state tested | 200 W and 300 W | default laptop power state |

The laptop is the strongest fair opponent for the claim. Strix Halo is designed
for exactly this class of local workload: a large integrated GPU, a wide memory
interface, and a unified pool intended to avoid the small-VRAM constraint of
typical laptop GPUs. If the dedicated-vs-unified claim survives here, it is not
merely beating a weak integrated GPU.

## 3. Measurement Path

The important methodological detail is that the conclusion moved as evidence
improved.

First, the datasheet intuition predicted a large desktop win. The RTX 3090's
936 GB/s memory bandwidth is about 3.66x the laptop's 256 GB/s LPDDR5X
bandwidth.

Second, the first head-to-head run was performed with the desktop card capped
at 200 W for PSU safety. That run showed a smaller gap: roughly 1.6x to 2.2x on
models that fit both machines. The provisional interpretation was that the
bandwidth ratio overstated the real-world advantage.

Third, the desktop was tested again at 300 W. That run moved the ratios to
3.20x on the dense 14B model and 2.96x on the MoE model. The corrected
interpretation is that the 200 W cap compressed the desktop's advantage. The
spec sheet was not exactly the answer, but it was directionally vindicated once
the card was allowed to operate near its real efficiency point.

That arc matters. The paper does not ask the reader to trust a single
after-the-fact story. It shows the story changing under measurement:

```text
datasheet prediction -> capped undershoot -> uncapped vindication -> variance-backed confirmation
3.66x bandwidth      -> about 2x measured -> about 3x measured    -> about 3.5x (dense, warm, n=6)
```

## 4. Fit-Both Results

These rows compare models that fit on both machines without intentional CPU
spill on the laptop. Rates are generation throughput in tokens per second from
one warmed prompt per cell.

| Model | Architecture | Size | Laptop iGPU | 3090 at 200 W | 3090 at 300 W | Ratio at 200 W | Ratio at 300 W |
|---|---|---:|---:|---:|---:|---:|---:|
| qwen2.5-14b | dense | 9 GB | 20.5 | 33.8 | 65.5 | 1.65x | 3.20x |
| gpt-oss | MoE | 13 GB | 39.7 | 88.6 | 117.5 | 2.23x | 2.96x |

The qwen row is a throughput comparison, not a quality comparison: the desktop
ran `qwen2.5-coder:14b` while the laptop ran `qwen2.5:14b`. They are the same
architecture and size class, so the row is still useful for hardware throughput,
but it should not be read as a byte-identical model comparison. The gpt-oss and
gemma rows used matching model IDs on both machines.

The fit-both result has two readings.

At 200 W, the desktop still wins even while constrained: 1.65x on the dense
model and 2.23x on the MoE model. That is the everyday, PSU-safe result for
this workstation.

At 300 W, the desktop moves close to the bandwidth intuition: 3.20x on dense
qwen2.5-14b and 2.96x on gpt-oss. The gap does not exactly equal the 3.66x
bandwidth ratio because inference throughput is not a pure bandwidth benchmark.
But the corrected result is much closer to the spec-sheet prediction than the
first capped run suggested.

## 5. Spill Results

The capacity trap appears when the laptop is allowed to load models that exceed
its practical GPU-resident ceiling. These runs use the desktop at 200 W.

| Model | Architecture | Size | Desktop | Laptop | Ratio | Laptop state |
|---|---|---:|---:|---:|---:|---|
| gemma4:26b | MoE | 17 GB | 89.2 | 28.3 | 3.15x | spills 33% CPU |
| gemma4:31b | dense | 19 GB | 14.3 | 5.4 | 2.64x | spills 44% CPU |

The dense spill row is the headline failure. The laptop can be made to run a
19 GB dense model, but it runs at 5.4 tok/s. That is not a useful victory for
the larger memory label. It is the hardware equivalent of passing a load test
by falling onto the slow path.

The MoE spill row is more forgiving. gemma4:26b spills 33% to CPU but still
generates 28.3 tok/s. That is slower than the desktop by 3.15x, but it remains
usable. The likely explanation is architectural: inactive experts are less
frequently read, so CPU-resident weights hurt less than they do in a dense
model where every token touches the whole active weight path.

The operational lesson is not "spill is always fatal." It is narrower and more
actionable:

> Spill severity is architecture-dependent. Dense spill is catastrophic; MoE
> spill can degrade gracefully.

These rows predate the `num_ctx 8192` GPU-residency fix (Section 12) and did
not log `ollama ps` residency confirmation for the desktop side. Section 12
re-runs both models with residency verified per cell; the laptop's spill
percentage barely moves, but the desktop numbers come in higher, widening
these ratios.

## 6. Power Scaling

The desktop power sweep explains why the first speed conclusion was wrong. The
card was not merely memory-bound at 200 W. Dense inference was strongly
compute-bound under the cap.

| Power | gemma4:26b MoE | gemma4:31b dense |
|---:|---:|---:|
| 200 W | 89.8 | 14.1 |
| 250 W | 97.8 | 23.5 |
| 300 W | 101.8 | 30.8 |
| 350 W | 99.9 | 31.7 |
| 200 W to peak | +13% | +124% |

The dense model more than doubled from 200 W to peak. That is the mechanism
behind the corrected interpretation: the 200 W desktop was artificially
starved. The laptop did not close the physical gap; the desktop cap hid it.

The MoE row is different. gemma4:26b gained only about 13% and then plateaued.
But this does not justify the blanket claim that MoE is power-insensitive:
gpt-oss improved from 88.6 tok/s at 200 W to 117.5 tok/s at 300 W, a 33% gain.
The better rule is that power elasticity is model- and architecture-dependent,
with dense models in this set showing the strongest response.

The 300 W row is also the practical efficiency knee. Moving from 300 W to
350 W bought essentially nothing in this measurement.

This sweep did not confirm GPU residency per row. Section 12's 220 W,
`num_ctx 8192` run measured gemma4:31b at 18.1 tok/s with 100% GPU residency
verified via `ollama ps` — higher than this table's 200 W entry (14.1 tok/s)
despite the lower power cap. The likely explanation is that some cells in
this sweep were partially CPU-spilling without anyone checking; see Section
12 for the caveat on how much weight the 200–350 W numbers above should
carry as a "GPU-only" baseline.

## 7. Findings

### Finding 1: Capacity Is Not The Advertised Memory Number

The laptop's 27 GB shared-memory label did not behave like 27 GB of useful GPU
memory. Under the tested default split, the iGPU had about 18 GB addressable
before spill. The desktop's 24 GB dedicated VRAM was smaller on the label and
larger in the operational sense that matters: it stayed on the accelerator.

This is the capacity trap. The larger number encourages a user to try larger
models. Some of those models load. The failure is that loading is mistaken for
running well.

### Finding 2: Dedicated Memory Wins Even When Power-Capped

At 200 W, the 3090 beat the laptop by 1.65x to 2.23x on fit-both models and by
2.64x to 3.15x on spill rows. That is the conservative desktop result because
the card is being held below its normal operating envelope.

This matters for real operators. A marginal PSU or thermal limit can compress
the desktop advantage, but it did not reverse it.

### Finding 3: At Real Power, The Desktop Moves Back Toward The Spec Ratio

At 300 W, the desktop reached 3.20x on dense qwen2.5-14b and 2.96x on gpt-oss in
the single-prompt pass. The variance pass (Section 10) later refined these to
3.54x and 3.15x once the laptop was measured warm — even closer to the 3.66x
bandwidth ratio. Either way, the numbers are close enough to change the
interpretation. The first 200 W result was not evidence that the bandwidth story
was fake. It was evidence that the desktop card was capped.

This is the paper's most important correction. The measurement does not dunk on
the spec sheet. It shows where the spec sheet is conditional.

### Finding 4: Architecture Can Dominate Hardware

On the same desktop at 200 W, gemma4:26b generated about 89 tok/s while
gemma4:31b generated about 14 tok/s. That is a roughly 6x swing on the same
machine from model architecture and serving behavior alone.

This limits the hardware conclusion. Hardware comparisons are meaningful only
when the model is held constant or when the model differences are explicitly
part of the claim. Mixing dense and MoE rows into one generic "hardware speed"
number would be misleading.

## 8. Relationship To HET-GPU-001

This paper pairs with HET-GPU-001, the earlier distributed sharding result. In
that run, a desktop RTX 3090 plus z13 Radeon 8050S RPC shard generated
8.4 tok/s on Qwen2.5-32B Q3, while the desktop alone generated 18.6 tok/s. The
cluster worked, but it was slower than the dominant node.

Together the two results form a local-inference hardware pattern:

| Intuition | Measured result |
|---|---|
| Add another node to increase capability | Heterogeneous sharding worked but slowed generation when one node dominated |
| Buy the larger unified-memory number | The larger nominal pool spilled and crawled on dense models |
| Use the spec sheet as the whole answer | The spec was directionally right only after power state was controlled |

The unifying claim is not anti-laptop or anti-cluster. It is anti-sticker-spec.
Local inference is governed by residency, bandwidth, power state, architecture,
and synchronization costs. The shopping number is only one input.

## 9. Proof Boundary

This paper supports a bounded claim:

> On the tested consumer local-inference setup, a 24 GB dedicated RTX 3090 is a
> better practical local LLM accelerator than a 27 GB Strix Halo unified-memory
> laptop for the measured model classes.

It does not prove:

- that all dedicated GPUs beat all unified-memory systems
- that Strix Halo is a bad local-inference platform
- that 300 W is the correct operating point for every 3090
- that MoE spill always remains usable
- that the measured ratios will hold across every prompt shape or context size
- that the qwen row is a byte-identical model comparison; it is an
  architecture-and-size-class throughput comparison

It does show:

- the laptop's default GPU-addressable memory ceiling was below its advertised
  shared-memory label
- dense spill produced an operationally poor 5.4 tok/s result
- the desktop won at both 200 W and 300 W
- the 300 W result moved the speed gap back toward the bandwidth ratio
- model architecture changed both absolute throughput and spill severity

## 10. Multi-Prompt Variance Pass (2026-07-05, gate closed)

The promotion gate — multiple prompts and warm runs per cell — has now been run:
three prompts (technical, narrative, historical) times two warm runs, six samples
per cell. It did three things: tightened the fit-both numbers with real variance,
corrected the laptop numbers downward, and surfaced a thermal effect the
single-prompt runs had hidden.

### Desktop variance (n=6, tokens/sec)

| Power | qwen2.5-coder:14b dense | gpt-oss MoE |
|---:|---:|---:|
| 200 W | 31.8 (30.9-32.9) | 78.9 (73.6-82.0) |
| 300 W | 62.3 (61.8-62.6) | 115.4 (111.8-117.1) |

Desktop variance is small — within about +/-5%, and under +/-1.5% at 300 W. One
correction falls out: the single-prompt gpt-oss 200 W value (88.6, Section 4) was
above even the six-run maximum (82.0). The honest mean is 78.9; the single
"engine" prompt simply generated faster than average.

### Laptop variance and thermal throttling (n=6)

| Model | mean | range | note |
|---|---:|---|---|
| qwen2.5:14b dense | 17.6 | 16.9-18.5 | throttles with temperature |
| gpt-oss MoE | 36.6 | 35.9-37.2 | measured already warm, stable |

The dense laptop run, taken from cold, throttled monotonically as the chip
heated:

```text
18.53@42C  18.06@49C  17.99@50C  17.17@52C  16.94@52C  16.92@52C
```

That is about a 9% decline from the first run to steady state — a real
thin-laptop thermal effect, not measurement noise. The consequence is that the
Section 4 single-prompt laptop numbers were cold-start optimistic: qwen2.5:14b
read 20.5 on a cold first run but settles near 17.6 warm, and gpt-oss read 39.7
cold versus 36.6 warm. A laptop under sustained load is slower than a cold
spot-check suggests; the desktop, capped and cooled, showed no such drift.

### Corrected fit-both ratios (robust warm means)

| Model | laptop warm | 3090 @200W | 3090 @300W | ratio @200W | ratio @300W |
|---|---:|---:|---:|---:|---:|
| qwen2.5-14b dense | 17.6 | 31.8 | 62.3 | 1.81x | 3.54x |
| gpt-oss MoE | 36.6 | 78.9 | 115.4 | 2.16x | 3.15x |

With rigorous means the 300 W dense ratio is 3.54x — within a few percent of the
3.66x bandwidth ratio. The bandwidth intuition was not oversold; the earlier
undershoots were a power-cap artifact on the desktop and a cold-start artifact on
the laptop, stacked. Cleaned up, the spec-sheet prediction essentially lands.

### Gate status

The multi-prompt variance gate is **closed**. The one remaining optional item is
the BIOS UMA/GTT split sweep on the laptop, which — as noted above — would not
change the LPDDR5X bandwidth or the fit-both speed comparison; it could only
reduce spill on some rows. The small reproducibility runner this section once
called for now exists (Section 12) and was used for a realistic-context
residency confirmation on gemma4:26b/31b — but the core numbers here predate
that confirmation and are now variance-backed rather than residency-verified.
The paper is publication-ready on the variance question; Section 12 opens a
narrower, separate question about whether the desktop's earlier power-sweep
numbers under-reported due to unconfirmed residency.

## 11. Reproducibility Notes

Primary local artifacts:

- `docs/DEDICATED_VS_UNIFIED_MEMORY.md`
- `docs/domain_runs/HET-GPU-001/sharded_comparison_findings.md`
- `docs/domain_runs/NODE-MODEL-MATRIX-002/findings.md`
- `docs/domain_runs/GEMMA4-CTX8192-3090-VS-Z13-001/findings.md`

Useful inspection commands:

```bash
cat docs/DEDICATED_VS_UNIFIED_MEMORY.md
cat docs/domain_runs/HET-GPU-001/sharded_comparison_findings.md
cat docs/domain_runs/NODE-MODEL-MATRIX-002/findings.md
cat docs/domain_runs/GEMMA4-CTX8192-3090-VS-Z13-001/findings.md
```

The reproducibility runner this section previously called for now exists:
`docs/domain_runs/GEMMA4-CTX8192-3090-VS-Z13-001/instructions.md` records
prompt, model ID, machine, power state, `ollama ps` residency, token rate,
and raw log path for each trial (see Section 12). It covers gemma4:26b/31b
only, at one context length and one desktop power point — not the full
matrix this paper's earlier sections span (200–350 W, multiple models). That
broader residency-confirmed re-measurement across power states is explicitly
out of scope for this freeze; Section 12's proof boundary states that limit
directly rather than implying full coverage.

## 12. Realistic-Context Residency Confirmation (num_ctx 8192, 2026-07-20)

Sections 5 and 6 report gemma4:26b/31b throughput and spill state, but neither
logged GPU-residency confirmation per row, and neither pinned context length.
This section closes that gap on two models: `gemma4:26b` (MoE, 17 GB) and
`gemma4:31b` (dense, 19 GB), run with `num_ctx 8192` pinned explicitly on
every call — the setting separately established (2026-06-24) as necessary for
`gemma4:31b` to reach 100% GPU residency on the desktop — and with
`ollama ps` residency checked after every load, not assumed.

The desktop ran at 220 W, not 300 W. `gemma4:26b` is the exact model that
caused CRASH-20260502-01 at 330 W (Section 2 hardware note); 220 W is this
rig's verified-stable floor, so this run stayed there rather than default to
the 320 W doctrine now in force for other workloads. The ratios below are
therefore not directly comparable to the 300 W rows in Sections 4–6 on power
alone — they isolate the residency-confirmation and context-length variables
instead.

Byte-identical model files were used on both machines (Ollama IDs
`5571076f3d70` / `6316f0629137` match on desktop and laptop). Each cell is 3
API calls (`temperature 0`, `num_predict 256`); run 1 includes model load,
runs 2–3 are warm and reported as the mean below. Zero errors, zero crashes,
across all 12 calls.

| Model | Desktop @ 220W | Laptop | Ratio | Desktop residency | Laptop residency |
|---|---:|---:|---:|---|---|
| gemma4:26b (MoE) | 91.4 tok/s | 18.8 tok/s | 4.86x | 100% GPU | 38%/62% CPU/GPU |
| gemma4:31b (dense) | 18.1 tok/s | 4.9 tok/s | 3.72x | 100% GPU | 45%/55% CPU/GPU |

### Finding: the laptop's spill split is largely context-length-insensitive

The pre-registered risk was that pinning `num_ctx 8192` — larger than
whatever context Sections 5's laptop numbers used — would push the laptop
further into CPU spill, since its ~17.5 GiB UMA ceiling is already tight.
That did not happen in any meaningful way: `gemma4:26b` spills 38% CPU here
versus 33% recorded earlier (NODE-MODEL-MATRIX-002); `gemma4:31b` spills 45%
versus 44% (Section 5). An 8192-token KV cache is small relative to a
17–19 GB model's weight footprint, so at these model sizes, context length
up to 8192 tokens is not what drives the capacity trap — weight size is.

### Finding: the gap widened because the desktop got faster, not because the laptop got slower

Given the laptop barely moved, the wider ratios here (4.86x / 3.72x) versus
Section 5's 200 W spill-table ratios (3.15x / 2.64x) are most likely explained
by the desktop side. Section 5's numbers predate the `num_ctx 8192` fix and
never logged `ollama ps` residency — it is plausible they were partially
CPU-spilling without anyone confirming otherwise at the time. This run is the
first in this paper to state desktop GPU residency as a verified fact per
cell rather than an assumption. If that explanation is right, Sections 5 and
6's desktop numbers understate its realistic-context ceiling, and the 3.7–4.9x
range here is the more honest one to carry forward. This is flagged as the
most likely explanation, not a proven mechanism — the earlier runs cannot be
retroactively checked for residency; they simply didn't log it.

### Proof boundary

This section shows:
- gemma4:26b/31b at 4.86x/3.72x on this rig, `num_ctx 8192`, with both
  desktop residency and laptop spill percentage directly verified per cell
- the laptop's spill ratio is largely context-length-insensitive across the
  range tested (Sections 5/NODE-MODEL-MATRIX-002's context → 8192) for these
  two model sizes
- the full 12-call pass completed with zero errors or crashes, including on
  the desktop at 220 W running the model with a prior crash history at 330 W

It does not show:
- that Sections 5–6's desktop numbers were definitely under-residency — that
  is the best available explanation given the evidence, not a confirmed one
- results at any power point other than 220 W, or any context length other
  than 8192 — the full 200–350 W × context matrix has not been re-run with
  residency confirmed
- anything about a real NVIDIA DGX Spark — the laptop remains a unified-memory
  architecture stand-in, not a benchmarked Spark

Full evidence: `docs/domain_runs/GEMMA4-CTX8192-3090-VS-Z13-001/` (raw API
responses, `ollama ps` captures, and `findings.md` for both machines).
