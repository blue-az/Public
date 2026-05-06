# Paper 1.25 — Orchestration Is Cheaper Than Reasoning

**Status:** revised 2026-05-04 — TSP evidence rebuilt from two verified runs
(`gemma4:26b` pre-cap and `gemma4:31b` post-cap). The original frozen draft
contained a fabricated TSP table; see Revision Note below.

**Paper group:** Local LLM Operator Judgment

## Working Claim

For reasoning-pattern local models on hardware with finite VRAM headroom,
the computational cost of "finding the answer" exceeds the cost of "explaining
the answer" by an order of magnitude. In agentic systems with a deterministic
oracle available, giving the model the oracle's result to orchestrate is
materially faster and *at least* as reliable as asking the model to solve the
problem from first principles. Scaling the local model up does not help, and
in this regime makes things measurably worse.

Findings from `gemma4:26b` (pre-cap) and `gemma4:31b` (post-cap, default 32k
context) on RTX 3090, Arizona TSP ladder:

- **The Verbosity Tax:** Direct-mode latency scales super-linearly with
  problem size. `gemma4:26b` direct time grows ~7s → 293s as cities go 4 → 10;
  `gemma4:31b` grows 151s → 1925s over the same range. Orchestrated time
  stays bounded by token-generation rate, not by reasoning depth.
- **The Reliability Rescue:** At world-100 scale `gemma4:26b` direct-mode
  drops 2 cities (Hanoi, Busan) but completes correctly when given the
  solver's tour to explain. On the Arizona ladder, both 26B and 31B find
  optimal in direct mode at every rung — i.e., on this task class, scaling
  the local model up buys nothing in quality. It only buys cost.
- **The Throughput Dividend:** The orchestration speedup grows with N for
  both models. At 10 cities, 26B's ratio is ~23×; 31B's is ~14×. 31B's
  orchestrated lane is also dragged down by spillage (~125s instead of 26B's
  ~12s), so its dividend tops out lower despite the bigger gap to its own
  direct lane.
- **The Scaling Anti-Dividend:** `gemma4:31b` orchestrated (~125s @ 10c) is
  about 11× slower than `gemma4:26b` orchestrated (~12s @ 10c) for the same
  optimal answer. Scaling the local model from 26B to 31B is a regression
  on this task class on this hardware. The optimal stack is the *smallest*
  model that holds correctness, plus a solver.
- **The Stability Tax (revised):** The CRASH-20260502-01 OCP trip happened
  on `gemma4:26b` (fully VRAM-resident, no spillage) at 99.4% of the 332W
  default limit. The current stable operating point is 220W. The 26B numbers
  below are pre-cap; the 31B numbers are post-cap. The cap does not affect
  31B comparability because 31B at default 32k context spills 6.7 GB into
  system RAM and runs CPU-bound, drawing only 165 W median — well under any
  cap that would matter.

## Evidence Anchor 1a: gemma4:26b Arizona Ladder (pre-cap)

`gemma4:26b` (MoE, ~17 GB resident, default Ollama quantization) on a single
RTX 3090, 332W default power limit.
Source: `domains/ExperimentalAgents/LocalLLMTSP/GEMMA4_BENCHMARK_NOTE.md`.

| Instance | Cities | Direct time | Orch time | Direct gap | Speedup |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `tsp-001` | 4 | 7.06s | 10.17s | exact tie | 0.7× (orch slower) |
| `tsp-002` | 5 | 100.85s | 10.38s | exact tie | 9.7× |
| `tsp-003` | 6 | 123.82s | 11.32s | exact tie | 10.9× |
| `tsp-004` | 8 | 181.31s | 10.58s | exact tie | 17.1× |
| `tsp-005` | 10 | 292.82s | 12.43s | exact tie | 23.6× |

## Evidence Anchor 1b: gemma4:31b Arizona Ladder (post-cap, spilled)

`gemma4:31b` (Q4_K_M, 19.9 GB weights + 32k context KV-cache → 31 GB total,
22.4 GB on GPU and 6.7 GB on CPU at default Ollama settings) on the same
RTX 3090, 220W power cap. Wall-clock for the full 5-fixture run: **117 min**.
Source: `docs/domain_runs/TSP_3090/` (results.jsonl, telemetry CSV, run log).

| Instance | Cities | Direct time | Orch time | Direct gap | Within-31B speedup | vs 26B Direct | vs 26B Orch |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `tsp-001` | 4 | 151.02s | 122.38s | exact tie | 1.2× | 21.4× slower | 12.0× slower |
| `tsp-002` | 5 | 1103.45s | 132.59s | exact tie | 8.3× | 10.9× slower | 12.8× slower |
| `tsp-003` | 6 | 1208.28s | 108.37s | exact tie | 11.2× | 9.8× slower | 9.6× slower |
| `tsp-004` | 8 | 2024.47s | 130.00s | exact tie | 15.6× | 11.2× slower | 12.3× slower |
| `tsp-005` | 10 | 1924.97s | 139.24s | exact tie | 13.8× | 6.6× slower | 11.2× slower |

Telemetry across the full 7045s run: median GPU utilization **22%** (mean
17%, peaks 100% during prefill), median power **165 W** (well under the
220W cap), VRAM steady at 23.7 GB. The GPU spent the majority of the run
blocked on PCIe round-trips to the 6.7 GB of weights resident in system RAM.
This is the operating point a default `ollama run gemma4:31b` produces on a
24 GB GPU.

Both lanes hit optimal on every rung for both models. The orchestration
dividend grows with N for both, but the *between-model* comparison is
unfavorable to 31B at every point: a bigger model on this hardware buys
nothing in quality and costs ~10× wall-clock.

## Evidence Anchor 2: ORCHESTRATION-001 (Scheduling)

A 20-fixture benchmark using `gemma4:26b` on complex scheduling tasks with 8-10 constraints.

| Metric | Lane A (Direct) | Lane B (Orchestrated) | Delta |
| :--- | :--- | :--- | :--- |
| **Accuracy** | 100.0% | 100.0% | 0.0% |
| **Latency (avg)** | **27.79s** | **11.48s** | **2.4x Speedup** |
| **Tokens (avg)** | **2,825** | **1,342** | **2.1x Saving** |

## Conclusion

The "Intelligence" of a local model is an expensive resource. In systems with
deterministic backends, the optimal use of this intelligence is as an
**interface and orchestration layer**, not a calculation engine.

The scaling comparison sharpens the claim: on the Arizona TSP ladder, both
`gemma4:26b` and `gemma4:31b` reach optimal in direct mode at every rung.
There is no quality dividend from scaling the local model up. There is, however,
a ~10× wall-clock penalty, because the larger model spills off the GPU at
default context and runs CPU-bound. By contrast, switching either model from
direct to orchestrated mode buys 9-23× speedup with no loss in correctness.

The right architectural choice is therefore the *smallest* local model that
holds correctness on the task class, paired with a deterministic solver. Scaling
the model up without scaling the hardware is not a path to better answers —
it is a path to slower answers that happen to be the same.

---

## Evidence Ledger

- **gemma4:26b Arizona TSP Ladder (pre-cap):** `domains/ExperimentalAgents/LocalLLMTSP/GEMMA4_BENCHMARK_NOTE.md`
- **gemma4:31b Arizona TSP Ladder (post-cap):** `docs/domain_runs/TSP_3090/report.md` (raw: `results.jsonl`, `nvidia_smi_telemetry.csv`)
- **ORCHESTRATION-001 Evidence Packet:** `docs/domain_runs/ORCHESTRATION_001/report.md` (raw: `results.json`)
- **Hardware Analysis (OCP Trip on gemma4:26b at 332W):** `docs/HARDWARE_CRASH_ANALYSIS_001.md`

## Revision Note (2026-05-04)

The original frozen draft (2026-05-02) included a `TSP-3090-001` table with a
`gemma4:31b` direct/orchestrated row (1028.9s / 545.5s) and a `gemma4:26b`
row (173.9s / 12.3s, "14× speedup") sourced to a `docs/domain_runs/TSP_3090/`
evidence packet. Audit found:

1. The `docs/domain_runs/TSP_3090/` directory did not exist; no such packet
   had been produced.
2. The repository contained no `gemma4:31b` TSP run. `gemma4:31b` had only
   been run on the PTS-001 synthesis-counterexample task surface.
3. The `gemma4:26b` numbers in the original table did not match the actual
   benchmark log at `domains/ExperimentalAgents/LocalLLMTSP/GEMMA4_BENCHMARK_NOTE.md`,
   which records 100.85s / 10.38s for the 5-city Arizona Clustered instance
   (real ~9.7× speedup, not 14×).
4. The original "Stability Tax" narrative attributed OCP trips to a 31B
   spillage mechanism. The actual CRASH-20260502-01 was on `gemma4:26b`
   fully VRAM-resident at 332W. The cited mechanism was wrong on both ends.
5. The "12.3s" 26B-orchestrated figure has no source in any TSP run; the
   closest match in the repository is 12.394s on a SCHED scheduling fixture
   in `ORCHESTRATION_001/results.json` — an unrelated task surface.

This revision (a) replaces the fabricated table with the real `gemma4:26b`
Arizona ladder, (b) adds a fresh `gemma4:31b` Arizona ladder run captured
with full GPU telemetry on 2026-05-04 (117 min wall-clock; results in
`docs/domain_runs/TSP_3090/`), (c) corrects the Stability Tax to match the
real CRASH-20260502-01, and (d) sharpens the architectural conclusion: the
two-model comparison shows scaling the local model up is an anti-dividend
on this task class, which strengthens rather than weakens the original
working claim.
