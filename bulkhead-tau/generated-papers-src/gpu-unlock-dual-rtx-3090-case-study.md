# GPU Unlock on Dual RTX 3090s: A Local Coding-Agent Workload Case Study

**Status:** published · **Date:** 2026-10-29 · **Paper number:** 1.49 (chronological) · **Paper group:** Local LLM Operator Judgment (confirmed)

**Study:** matched stock and `gpu-unlock` 1.0.0 runs on one operator-owned Local Lane task

## Abstract

This case study measures a dual-RTX-3090 system before and after enabling `gpu-unlock` 1.0.0, using two local coding-agent model routes on the same operator-owned `constant-and-callers` L2 task. Each model/condition cell has three unseeded trials. Both routes had lower median task-session time in the unlocked condition: Qwen3.8-27B went from 15.0 to 13.1 seconds, and Qwen3.6-35B-A3B from 5.6 to 5.3 seconds. The lower session times do not imply a uniform throughput gain. Weighted incremental prefill fell 19.1% for Qwen3.8-27B and rose 6.7% for Qwen3.6-35B-A3B; decode changed by only +1.0% and +3.4%, respectively. All twelve task trials passed, and all selected tool calls were valid.

The result is exploratory, not a general GPU-unlock claim. The sample is small, the model-selected tool trajectories were unseeded, and Qwen3.8-27B used fewer calls in its unlocked trials. The measured task is a small CAC L2 maintenance task, not a 12-step benchmark or a replication of a different author's workload.

## 1. Question and scope

The question is practical: on this particular dual-3090 coding-agent setup, what changed when the cards were run with `gpu-unlock` enabled, while keeping the Local Lane task, models, server configuration, driver, power limits, and request settings fixed?

This is a within-system case study, not a controlled estimate of the effect across GPUs, models, tasks, or software stacks. The two conditions were run sequentially on 2026-10-29, stock first and unlocked second. Within each condition, the models ran sequentially in the order shown. There was no randomized or counterbalanced order. The paper reports the observed run medians and server timings, without significance testing or causal generalization.

## 2. System and conditions

| Item | Setting |
|---|---|
| GPUs | 2× RTX 3090; GPU0 at `0000:01:00.0` (CPU x16), GPU1 at `0000:03:00.0` (chipset x4) |
| Host | Debian 13; kernel `6.12.111+deb13-amd64`; NVIDIA driver `550.163.01` |
| Unlock | `gpu-unlock` 1.0.0, built from checksum-verified 610.43.03 firmware inputs; both BDFs targeted; no P2P patch |
| Power and thermal guard | 350 W/card power limit in both conditions; 85 °C stop threshold |
| Inference server | llama.cpp `b1-2851b3b`; 196,608-token configured context; layer split; 999 GPU layers; flash attention on; parallelism 1 |
| Qwen3.8 route | Qwen3.8-27B, Q4_K_M weights, F16 K/V cache |
| Qwen3.6 route | Qwen3.6-35B-A3B, Q4_K_M weights, Q8_0 K/V cache |
| Workload | Local Lane `constant-and-callers` L2: a bounded, multi-file retry-limit edit followed by its fixture check |
| Sampling | Per-request temperature 0.8, top-p 0.95, top-k 20, min-p 0, presence penalty 0, repeat penalty 1; thinking off; 4,096-token request cap |
| Replication | Three trials per model per condition; models run sequentially; no fixed random seed |

The model routes were not simultaneously resident. The requested sampler values are taken from captured API request options, which explicitly carried these values on the measured requests in both conditions. In the unlocked packet, the server's separate `/props` snapshots reported different defaults for some fields (Qwen3.8 temperature/min-p and Qwen3.6 top-k/min-p); those defaults are not substituted for the explicitly logged per-request options.

The unlocked boot log recorded the module's unlocked state for both target GPUs and NVIDIA DRM initialization. During unlocked trials, telemetry peaks were 79 °C and 76 °C, with peak power of 320 W and 310 W, below the unchanged 350 W/card limits and below the stop threshold.

## 3. Results

### Qwen3.8-27B

| Metric | Stock | Unlocked | Observed change |
|---|---:|---:|---:|
| CAC L2 task-session median | 15.0 s | 13.1 s | −12.7% time |
| Incremental prefill, weighted | 467 tok/s | 378 tok/s | −19.1% |
| Exact final-context replay median | 2,394 tokens / 3.401 s | 2,292 tokens / 3.202 s | −5.8% time; context sizes differ |
| Fresh replay prefill median | 1,293 tok/s | 1,423 tok/s | +10.1% |
| Agent-request decode, weighted | 42.42 tok/s | 42.84 tok/s | +1.0% |
| Correct task trials | 3/3 | 3/3 | all passed |
| Valid tool calls | 24/24 (8, 7, 9) | 20/20 (7, 7, 6) | all valid; path/count varied |

### Qwen3.6-35B-A3B

| Metric | Stock | Unlocked | Observed change |
|---|---:|---:|---:|
| CAC L2 task-session median | 5.6 s | 5.3 s | −5.4% time |
| Incremental prefill, weighted | 868 tok/s | 926 tok/s | +6.7% |
| Exact final-context replay median | 2,543 tokens / 1.870 s | 2,542 tokens / 1.806 s | −3.4% time |
| Fresh replay prefill median | 1,790 tok/s | 1,841 tok/s | +2.9% |
| Agent-request decode, weighted | 153.39 tok/s | 158.62 tok/s | +3.4% |
| Correct task trials | 3/3 | 3/3 | all passed |
| Valid tool calls | 23/23 (7, 8, 8) | 23/23 (7, 8, 8) | all valid; same counts |

The task-session latency excludes model load. It includes the agent's variable task trajectory, so it is not a fixed-token inference benchmark. In particular, Qwen3.8-27B made four fewer tool calls in the unlocked trials; that trajectory change may contribute to the shorter session median. The Qwen3.6-35B-A3B trials had the same tool-call counts across conditions, but the three-trial sample still does not establish a stable effect.

## 4. Measurement definitions

- **Incremental prefill:** `sum(prompt_n) / sum(prompt_ms)` over non-initial agent requests. This weighted server-side rate is separate from the fresh replay measurement.
- **Fresh replay prefill:** median of each trial's llama.cpp `prompt_per_second` for an exact replay of the final messages and tools, with prompt cache disabled and a 64-token output cap.
- **Agent-request decode:** weighted `sum(predicted_n) / sum(predicted_ms)` over the agent's requests. It is server timing, not client wall-clock latency.
- **Task correctness and tool validity:** correctness is the fixture grader's pass/fail result; tool validity counts whether selected calls were valid. They are reported separately.

The actual final histories were approximately 2.3–3.0K tokens. This study is not a 12-step task, and its values should not be presented as a direct replication or head-to-head comparison with a separate reference workload.

## 5. Interpretation

The narrow observation is that both model routes had lower median CAC L2 session time after the unlock, while server-side throughput results were mixed. Qwen3.8-27B's incremental prefill rate was lower, even as its fresh replay rate was higher; Qwen3.6-35B-A3B improved modestly across the reported server rates. Decode-rate changes were small for both models.

These measurements do not show that `gpu-unlock` makes coding agents generally faster. They do show why a single headline number is inadequate: the answer depends on whether the measurement is a variable agent session, a fresh replay, incremental prefill, or decode—and on which model route is being used. For this workload, the smaller relative session-time change on the already faster Qwen3.6-35B-A3B route is consistent with a lower available latency ceiling, but three trials cannot establish that explanation.

## 6. Limitations and evidence notes

1. **Small, unseeded sample:** three trials per model/condition on one task; tool paths were model-selected and variable. No inferential statistics are claimed.
2. **Sequential conditions:** stock ran before unlocked, without counterbalancing; time/order effects are not ruled out.
3. **Single hardware/software stack:** results bind to this dual-3090 topology, 350 W/card settings, driver, llama.cpp build, quantizations, cache types, and Local Lane route.
4. **Placement evidence boundary:** a separate live gate recorded the same server process using both expected GPU UUIDs before task inference, with per-card memory records. The saved per-trace `proofs.placement` field is nevertheless false. Placement is supported by the independent run-level gate and placement records, not by that trace boolean.
5. **Sampler reporting:** captured request payloads carried the stated parameters; the server properties endpoint separately reported defaults that differed for some fields. The paper distinguishes these sources rather than treating server defaults as effective request settings.
6. **Metadata correction:** the unlocked packet's first summary output inherited the stock study identifier. The raw summary was retained, the metadata-only correction was recorded, and the trial results file was not changed.
7. **No power-limit change:** both cards stayed at 350 W/card. This is not a test of higher power limits, overclocking, or a different driver.

## 7. Reproducibility and data availability

The stock and unlocked experiment packets are identified as `QWEN-DUAL-LANE-CAC-001` and `QWEN-DUAL-LANE-CAC-UNLOCKED-001`; the unlocked run began at `20261029T085122Z`. Raw traces, request timing records, exact replay inputs, placement artifacts, and telemetry were retained in the local evidence packets. They are not reproduced here because the task fixture and agent traces are operator-owned. The aggregate trial counts, formulas, model/server settings, and limitations needed to interpret this case are included above.

## Conclusion

On one small, operator-owned coding-agent task, the dual-RTX-3090 unlocked condition coincided with lower median task-session times for both tested model routes. The component throughput results were mixed, and the Qwen3.8-27B tool trajectory changed between conditions. The defensible result is therefore workload-specific: measure the task and metric that matter on the target system; do not infer a general speed-up from this case study.
