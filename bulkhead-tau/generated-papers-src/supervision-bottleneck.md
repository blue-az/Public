# When Tokens Are Plentiful, Supervision Becomes the Bottleneck (Under Coarse Quota Regimes)

**Date:** 2026-06-18  
**Project:** Phoenix / Bulkhead τ  
**Domain:** AGY-GEMINI-QUOTA-001  
**Status:** DRAFT (Analysis Complete)

## Abstract

This paper analyzes the operational dynamics of multi-agent development under the specific coarse quota regimes of the late-Gemini CLI transition. Using the Bulkhead τ game suite as a testbed, we demonstrate that while raw model implementation capacity appears effectively limitless on visible percentage meters, the true bottleneck remains the human-supervised "command and control" layer. Operational evidence suggests that in environments with abundant but opaque implementation tokens, scarcity shifts to specification clarity, role discipline, and the cognitive cost of verification — a dynamic we term the **agentic overhang**: implementation throughput that outruns the human's capacity to direct and audit it.

## 1. Operational Context

Project Phoenix utilizes a multi-model stack (Claude Code, Antigravity CLI, Gemini CLI, Codex) for both production agents and development assistance. In measurement run AGY-GEMINI-QUOTA-001, we assigned Antigravity (Agy) as the **Supervisor** and Gemini as the **Implementer**. The goal was to measure the "cost" of large game redesigns and repo-wide synchronization tasks when implementation capacity is high but visibility is low.

## 2. Measurement Method

We tracked two distinct metrics, prioritizing the former as the "ground truth":
1. **Hidden Activity (Primary):** Cumulative request counts, input/output tokens, and tool calls (via `/stats`).
2. **Visible Meter Signal (Secondary/Deceptive):** The coarse percentage-based "fuel gauge" provided by tool interfaces.

## 3. Evidence Segments

### 3.1 Damage Control Redesign (High Activity, Coarse Signal)
Gemini implemented a large-scale redesign of the Damage Control game.
- **Hidden Activity (Primary):** +9 `gemini-3-flash-preview` requests; ~806k total input tokens.
- **Visible Meter Signal:** Gemini read 11% at sampling — no movement resolvable at the meter's granularity for this segment.
- **Supervisor Overhead:** Agy consumed 3% visible quota; required 6 additional human reviews.
- **Finding:** ~0.8M tokens of activity produced no resolvable change on the coarse Gemini meter, shifting the perceived "cost" entirely to the supervisor lane.

### 3.2 Protocol Failure Case Study: Voyage v2 (Role Contamination)
Intended as a split-lane task, Agy (Supervisor) implemented the code directly due to a handoff ambiguity.
- **Result:** Agy spent 5% visible quota performing the work Gemini was assigned.
- **Lesson:** This segment represents a failure in protocol rather than clean data. It illustrates that role ambiguity leads to "supervisor leakage," where the more expensive supervisor quota is wasted on tasks meant for the implementation lane.

### 3.3 Messenger Cozy Redesign (The Verification Floor)
A small behavioral redesign of Messenger was tasked to Gemini.
- **Hidden Activity:** +2.4M total input tokens (includes +1.9M `gemini-3.1-pro-preview` for verification).
- **Visible Meter Signal:** Gemini still read 11% at sampling — below the meter's resolution for this segment.
- **Supervisor Overhead:** Agy consumed 6% visible quota.
- **Finding:** Even small edit surfaces trigger high-capability verification lanes, consuming significant tokens (~2.4M) that registered on the supervisor's meter but not the implementer's coarse one.

### 3.4 Autonomous Repo Sync (Scaling the Implementer)
Gemini performed a multi-file sync and alignment pass across five games.
- **Hidden Activity:** +1.6M total input tokens (includes +1.3M `gemini-3-flash-preview` delta).
- **External QA Cost:** 3% Claude quota (for a single critical correction).
- **Finding:** Implementation scaling is limited only by human-initiated QA and playtest verification, not by the implementer's turn capacity.

### 3.5 Router Implementation (The Granularity Contrast)
Codex wrote the spec; Gemini implemented.
- **Plan Activity (Codex):** 7% visible quota (Spec) + 6% (Recording).
- **Build Activity (Gemini):** +19 requests (~929k tokens); no resolvable meter movement at sampling.
- **Finding:** Planning registers on visible meters while implementation barely does under this regime. The perception that planning is more expensive is an artifact of meter granularity, not actual token cost (the build consumed nearly 1M tokens).

## 4. Findings

### 4.1 Deception of the Coarse Meter
Visible % meters are untrustworthy and non-comparable. Gemini's visible quota moved only ~15% in total across the entire effort, and read a static 11% through several large implementation segments — far too coarse to attribute or compare the roughly 5.85 million input tokens of measured activity (the sum of the audited per-segment deltas: §3.1 ~0.8M + §3.3 ~2.4M + §3.4 ~1.6M + §3.5 ~0.9M). Sampling of the meter also lapsed once attention shifted to capturing token-level stats, so even the ~15% figure is an approximate ceiling, not a per-segment signal. (Single-session cumulative token totals are larger but are not directly comparable across sessions, per the measurement notes.) Relying on these meters for "cost" analysis invites the false conclusion that implementation is nearly free, when it is merely under-resolved.

### 4.2 The Supervision & Verification Bottleneck (the Agentic Overhang)
We term this dynamic the **agentic overhang** — by analogy to the established *capability overhang* (latent model capability that outruns our ability to elicit it), the agentic overhang is implementation throughput that outruns our ability to *direct and audit* it. Agents work at high volume continuously, but high-bandwidth human auditing has not caught up: a five-file refactor takes the model seconds to propose and the human many minutes of deep focus to be *sure* no subtle defect was introduced — making the operator the **synchronous step in an otherwise asynchronous system**. The phenomenon itself is widely recognized in practice (the "human-oversight bottleneck" / "speed gap"); the *agentic overhang* label (after capability overhang) is our framing for it, not yet established terminology. In this regime the binding constraints shift to:
- **Human Attention:** Reviewing batch changes for "fun" and "feel," which automated syntax checks do not capture.
- **Operational Visibility:** The cognitive load of tracking ~5.85M tokens of hidden implementation activity across multiple tools.
- **Specification Clarity:** The "Plan" phase consumes visible supervisor budget and human coordination time, making it the perceived bottleneck even when the "Build" phase consumes more total tokens.

## 4.3 Large Batches > Tiny Tasks
Under coarse quota regimes, large bounded tasks are more efficient. Small turns burn human coordination bandwidth and supervisor quota without significantly reducing implementation risk, as the implementer's capacity to "fix" its own large batches barely registers on the coarse visible meter.

## 5. Failure Modes

- **Implementation Leakage:** Without hard-gated roles, supervisors will perform implementation directly, wasting high-visibility quota on low-visibility tasks.
- **The "Verify-by-Running" Trap:** Code-running verification confirmed syntax and state changes but failed to catch if games were "pleasant" or "fair." Physical playtesting remains the only valid verification for game balance.

## 6. Operating Rules for Abundant Tokens

1. **Prefer Batching:** Group related implementation tasks into large instruction blocks to minimize human/supervisor review cycles.
2. **Hard-Gate Roles:** Supervisors must be forbidden from editing code to preserve their high-visibility quota for orchestration.
3. **Trust Stats, Not Meters:** Only `/stats` (token/req counts) provide a valid ground truth for activity.
4. **Assume High Hidden Cost:** Treat a small or static meter reading as uninformative — a coarse meter under-resolves and lags true activity, so flat ≠ free.

## 7. Limitations

- **Regime Specificity:** These findings are unique to the coarse, turn-limited transition period of the Gemini CLI and may not apply to fine-grained usage-based APIs.
- **Sample Size:** Limited to five game surfaces in a single development session.

## 8. Conclusion

The transition to a supervision-scarce environment requires shifting engineering focus from "token efficiency" to "attention efficiency." When implementation activity is high but barely registers on coarse meters, the highest-ROI activities are precise specification, rigorous role boundaries, and final human playtesting.

---

### Provenance
*Captured at completion of paper drafting.*

- **Session ID:** ddbe24eb-9961-434b-8382-69420812f469
- **Tool calls:** 10 (9 successful, 1 failed)
- **User agreement:** 100.0% (9 reviewed)
- **Drafting activity:** Paper creation and two subsequent logical/numerical refactors.
- **Visible Gemini Quota:** ~11% during early sampling; ~15% used in total across all work. The meter was sampled sparsely once token-level capture began, so per-segment readings are approximate.

