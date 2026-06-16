# When Local LLM Clusters Do Not Help
## A Negative Result on Heterogeneous Consumer Inference
### White Paper 1.39 — June 2026

**Author:** blue-az
**Status:** Published
**Paper group:** Local LLM Operator Judgment
**Evidence packets:** `docs/domain_runs/HET-GPU-001/`, `docs/domain_runs/NODE-MODEL-MATRIX-001/`, `docs/domain_runs/NODE-MODEL-MATRIX-002/`
**Predecessors:** `SLOW_IS_NOT_SMART.md`, `LOCAL_MODELS_COST_FRONTIER_TOKENS.md`

---

## Abstract

A heterogeneous local cluster can be useful infrastructure without being useful
inference hardware. This paper reports a negative result from a three-node
consumer cluster: a desktop RTX 3090, an AMD z13 laptop with Radeon 8050S UMA,
and an Intel Mac Mini. The cluster successfully supported remote orchestration:
the desktop pushed instruction packets, triggered node-local model runs, and
pulled evidence back from both remote machines. However, it did not extend the
usable local-inference frontier. RPC sharding across desktop and z13 worked but
was slower than keeping the same model resident on the RTX 3090. Remote offload
also failed to create a useful niche: z13's GPU-resident ceiling stopped at the
20B class, while 26B/27B models spilled to CPU; the Intel Mac Mini was CPU-only
for this lane. The conclusion is narrow but operationally important: for this
hardware and workload class, cluster orchestration is viable, but heterogeneous
distributed inference is not.

---

## 1. Claim

The common local-inference intuition is that spare machines can be combined to
make a stronger model host. That intuition fails when one node dominates both
compute and practical memory residency.

The defended claim:

> A heterogeneous local cluster may improve operational control, file movement,
> and evidence collection, but it does not necessarily improve inference
> capability. If one node dominates the cluster, distributed sharding and remote
> offload can add complexity without moving the usable model frontier.

The claim is empirical and bounded. It does not argue that distributed inference
is generally bad. It argues that this specific consumer cluster does not earn
the distributed-inference lane.

---

## 2. Hardware Under Test

| Node | Role | Relevant capability |
|---|---|---|
| Desktop | dominant local inference node | RTX 3090, 24 GB VRAM |
| z13 | candidate remote/offload node | Radeon 8050S via Vulkan/RADV, about 17.5 GiB practical UMA allocation ceiling |
| Mac Mini | candidate remote node | Intel i7-8700B, 8 GB RAM, CPU-only for this lane |

The desktop was already the known strong node. The only decision-relevant
question was whether either remote node could host or accelerate a model class
that the desktop could not handle better.

---

## 3. Evidence Packets

The empirical basis for this paper consists of three target experiments carried out across the cluster nodes:

| Experiment | Core Question | Key Result | Reference Path |
| :--- | :--- | :--- | :--- |
| **HET-GPU-001** | Can heterogeneous RPC sharding improve generation speed? | **Negative.** Succeeded but net-negative (8.4 tok/s sharded vs. 18.6 tok/s desktop-local) due to latency/asymmetry overhead. | `docs/domain_runs/HET-GPU-001/sharded_comparison_findings.md` |
| **NODE-MODEL-MATRIX-001** | Can the desktop coordinate remote node execution and collect evidence? | **Positive.** Control-plane SSH orchestration, remote execution, and automated evidence retrieval successfully verified. | `docs/domain_runs/NODE-MODEL-MATRIX-001/findings.md` |
| **NODE-MODEL-MATRIX-002** | What is the maximum 100% GPU-resident model size each weak node can run? | **Memory-Bounded.** z13 ceiling is 20B (`gpt-oss:20b` @ 27.2 tok/s); 26B+ spills to CPU. Mac Mini is CPU-only. | `docs/domain_runs/NODE-MODEL-MATRIX-002/findings.md` |

### 3.1 HET-GPU-001 — RPC Sharding Works, But Loses

`docs/domain_runs/HET-GPU-001/` tested a sharded `Qwen2.5-32B-Instruct-Q3_K_M`
run across the desktop RTX 3090 and z13 Radeon 8050S.

The sharded run succeeded:

```text
{"status":"ok","lane":"rpc-sharded-q3"}
```

Measured performance:

| Mode | Generation throughput |
|---|---:|
| Desktop RTX 3090 local | 18.6 tok/s |
| z13 local GPU | 7.0 tok/s |
| Desktop + z13 RPC sharded | 8.4 tok/s |

The sharded path improved on z13-local execution but lost badly to the desktop
local path. That matters because the desktop is the actual baseline operator
choice. A distributed path that is 2.2x slower than the single dominant node is
not an operational win.

The z13-authored RPC socket note adds a useful caveat: one inspected server-log
window did not show the desktop connection. The desktop evidence packet still
contains a successful sharded completion and RPC-capable `llama-cli` binaries.
The reconciled conclusion is not "RPC failed"; it is "RPC works, but is not worth
using for this hardware."

### 3.2 NODE-MODEL-MATRIX-001 — Orchestration Works

`docs/domain_runs/NODE-MODEL-MATRIX-001/` tested whether the desktop could
coordinate remote node inference work.

Result: PASS.

The desktop successfully:

- pushed instruction packets to z13 and Mac
- verified remote reachability
- triggered or coordinated node-local model runs
- pulled evidence back into the repository

z13 completed coordinator-fired Ollama runs:

| Model | Result |
|---|---|
| `llama3.2:3b` | exact `Z13_OK` |
| `qwen2.5:3b` | exact `Z13_COORD_OK` |

Mac completed two paths:

| Runner | Model | Result |
|---|---|---|
| Ollama | `qwen2:0.5b` | PASS |
| Camelid | TinyLlama Q8 GGUF | PASS, 5.48-5.66 tok/s |

This packet changes the status of cluster orchestration from unconfirmed to
confirmed. The machines can be driven remotely. The evidence-return path works.
The useful infrastructure claim is real.

### 3.3 NODE-MODEL-MATRIX-002 — Remote Offload Lane Closed

`docs/domain_runs/NODE-MODEL-MATRIX-002/` deliberately avoided a 21-cell sweep.
It asked the one decision-relevant question:

> What is the largest model each weak node can run fully GPU-resident, with no
> CPU spill?

Measured result:

| Node | GPU-only ceiling | Notes |
|---|---|---|
| z13 | `gpt-oss:20b` | about 14 GB UMA footprint, 100% GPU, 27.21 tok/s |
| z13 | `qwen2.5:14b` | also resident, 9.7 GB footprint, 12.66 tok/s |
| z13 | `gemma3:27b`, `gemma4:26b` | spill to CPU, 38%/62% CPU/GPU |
| Mac Mini | none | CPU-only for this lane |

This closes the remote-offload lane. The z13 cannot host the 26B/27B class
without CPU spill, and the Mac Mini contributes no useful GPU lane. Neither
remote node hosts a model class that the desktop RTX 3090 cannot already handle
better.

---

## 4. Why The Full Matrix Was Parked

The original temptation was to run a broad node-by-model matrix. That would have
produced more rows but not more decision value.

The prior paper `SLOW_IS_NOT_SMART.md` already established the task-level
principle: bigger local models do not automatically improve bounded validated
lanes. HET-GPU-001 already showed that sharding is not competitive with the
dominant node. The only remaining unknown was the weak nodes' GPU-resident
ceilings. NODE-MODEL-MATRIX-002 answered that with one number per node.

The parked matrix is an example of benchmark discipline:

- do not run a sweep when a single discriminating probe answers the decision
- do not convert curiosity into a cross-cluster workload
- do preserve the negative result when it closes a lane

---

## 5. Interpretation

The result splits the cluster into two separate claims.

### 5.1 Compute Claim: Failed

The cluster does not extend local model capability in a useful way.

- z13 is weaker than the RTX 3090 on the relevant model classes.
- Mac Mini is CPU-only for this lane.
- RPC sharding works but is slower than desktop-local execution.
- Oversized models were already unsupported by the task-level evidence: bigger
  did not buy useful correctness on the measured bounded tasks.

The compute lane is closed.

### 5.2 Orchestration Claim: Confirmed

The cluster is useful as operational infrastructure.

- remote instruction packets work
- SSH orchestration works
- node-local probes can be triggered without USB shuttling
- evidence can be pulled back into the repo
- Camelid has value as a control/file-transfer layer even when it is not a
  distributed-inference win

The orchestration lane remains open.

---

## 6. Boundaries

This paper does not claim:

- that all distributed inference is bad
- that homogeneous GPU clusters fail
- that high-bandwidth interconnects would have the same result
- that remote nodes are useless for non-inference work
- that local inference is useless

It claims only:

- this heterogeneous consumer cluster does not beat the dominant RTX 3090 for
  local inference
- remote offload does not create a useful large-model niche here
- orchestration value should not be confused with inference value

The strongest positive result is intentionally retained: remote node
orchestration works.

---

## 7. Practical Rule

Before treating spare machines as a local LLM cluster, ask three questions in
order:

1. Can any remote node host a useful model class that the dominant node cannot?
2. If sharding works, is it faster than the dominant node alone?
3. Does the target task actually benefit from the larger model class?

For this cluster, the answers were:

1. no
2. no
3. not on the bounded measured lanes

That is enough to close the inference lane without further sweeping.

---

## 8. Reproducibility Commands

Inspect the evidence packets:

```bash
cat docs/domain_runs/HET-GPU-001/sharded_comparison_findings.md
cat docs/domain_runs/HET-GPU-001/desktop_evidence/evidence/desktop_rpc_sharded_31b_q3_manifest.txt
cat docs/domain_runs/HET-GPU-001/z13_to_desktop_rpc_smoke.md

cat docs/domain_runs/NODE-MODEL-MATRIX-001/findings.md
cat docs/domain_runs/NODE-MODEL-MATRIX-001/mac_evidence/evidence/report.md
cat docs/domain_runs/NODE-MODEL-MATRIX-001/z13_evidence/evidence/report.md

cat docs/domain_runs/NODE-MODEL-MATRIX-002/GPU_CEILING_PROBE.md
cat docs/domain_runs/NODE-MODEL-MATRIX-002/findings.md
```

Verify the key numeric claims:

```bash
grep -R "18.6\\|8.4\\|7.0\\|27.21\\|38%/62%\\|5.48-5.66" docs/domain_runs/HET-GPU-001 docs/domain_runs/NODE-MODEL-MATRIX-001 docs/domain_runs/NODE-MODEL-MATRIX-002
```

---

## 9. Conclusion

The negative result is the useful result.

The cluster can coordinate work, transfer packets, trigger node-local runs, and
collect evidence. That is real infrastructure. But it does not create a better
local inference lane than the desktop RTX 3090. The z13 tops out below the
large-model class that would matter, the Mac Mini is CPU-only for this lane, and
RPC sharding adds enough overhead and asymmetry to lose against the single
dominant node.

Therefore the correct operational posture is:

> Use the cluster for orchestration. Do not use it for heterogeneous distributed
> inference on this hardware.
