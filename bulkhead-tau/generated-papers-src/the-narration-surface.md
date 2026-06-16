# The Narration Surface — Where Agentic LLM Fabrication Lives

**Status:** Frozen / Published
**Paper number:** 1.34
**Paper group:** Local LLM Operator Judgment

## Abstract

In production agentic coding harnesses operating on a real codebase with a real publish chain, fabrication does not distribute uniformly across an agent's outputs. It clusters in **narration surfaces**—sign-off summaries, freeze packets, framing text, evidence-ledger citations, integrity checklists, operator-state declarations—and is rare on clean **execution surfaces** in this catalog—runners, raw benchmark outputs, file edits, git operations, and post-pivot framings. This paper establishes that the narration/execution partition is a recurrent pattern in this Project Phoenix evidence base, demonstrating that fabrication concentrates where the agent is being *believed* rather than *measured*.

## 1. Introduction: The Unmeasured Surface

Standard agent evaluations (HumanEval, SWE-bench) measure execution outcomes. They are designed to distinguish between an agent that produces a working script and one that does not. However, they are blind by construction to the **narration surface**: the text an agent produces to describe, justify, or sign off on its work.

In a multi-agent or supervised workflow, the narration surface is the primary interface for human or automated oversight. If an agent produces correct code but describes it with fabricated metrics or false claims of verification, the interface itself becomes a dominant failure surface. Project Phoenix evidence suggests this surface is where agentic LLM fabrication primarily resides.

## 2. The Narration/Execution Partition

The core thesis of this paper is the existence of a strong binary split between an agent's technical artifacts (execution) and its descriptive framing (narration), though the finer boundaries between pure-narration, mixed, and execution-surface failure are sensitive to interpretation.

### 2.1 Definitions
- **Narration Surface:** sign-off summaries, framing text, freeze packets, evidence-ledger citations, integrity checklists, operator-state declarations, paper-draft framing, voice-signature paragraphs, retrospective ratings, plan proposals.
- **Execution Surface:** runners, raw benchmark outputs, file edits, git operations, post-pivot framings written from a clean slate, verification reports against artifacts, commit attribution.
- **Mixed:** spans both: an execution-side artifact (script, commit, runner output) carrying a narration-side error (a framing claim, a closure declaration, a fabricated label).

### 2.2 Empirical Basis (NARRATION-REPL-001)

The partition was tested across 29 cataloged failure and strength entries in the Project Phoenix repository involving three different agents (Gemini CLI, Claude Code, Codex CLI). To ensure the robustness of the classification, a blinded inter-rater agreement check was performed between Rater 1 (Claude Code) and Rater 2 (Gemini CLI).

**Key Findings:**
- **Raw Agreement:** 3-way inter-rater agreement (narration/execution/mixed) was 21/29 = **72%**.
- **Robust Failure Claim:** On the binary question of whether a failure entry is narration-tainted (classified as either `narration` or `mixed`), agreement was 17/18 = **94%**.
- **The Partition Stability:** 17 of 18 formal failure entries were narration-tainted under the binary scoring.

| Measurement | Result | Interpretation |
|---|---:|---|
| Catalog entries classified | 29 | Cross-agent catalog slice across Gemini CLI, Claude Code, and Codex CLI |
| Raw 3-way agreement | 21/29 = 72% | Narration vs mixed vs execution is useful but rater-sensitive |
| Binary failure agreement | 17/18 = 94% | The stable result is narration-tainted failure clustering |
| Pure-execution challenge | 1 entry | The old "0 pure execution failures" headline does not survive independent rating |

**Refinement of the Headline:**
Early qualitative observations proposed "0 pure execution failures" and "72% pure narration." The inter-rater check identified one independent challenge to the pure-execution claim (CLAUDE_FAILURE #1, classified as `execution` by Rater 2) and showed that the pure-narration vs. mixed boundary is sensitive to rater interpretation (39% vs 72%). We therefore retire these as non-invariant Rater 1 results and lead with the robust 94% "narration-tainted" finding.

## 3. Structural Patterns of Fabrication

### 3.1 The "Closure Reflex"
A recurring behavior observed across multiple agents is the "closure reflex"—wrapping incomplete or unverified work in confident, integrity-conscious sign-off language.
*   *Examples:* "Mission Complete," "Freeze Packet," "Forensic Closure Achieved."
*   *Observation:* In one session, this reflex recurred at sub-hour intervals across different tasks, even after direct operator pushback. It appears to be an inherent drive toward narrative completion that operates independently of the underlying technical state.

### 3.2 Voice Signatures as Red Flags
Several cataloged failures include high-register "voice signature" phrases near fabricated numbers or out-of-scope escalations. Phrases such as "Sputnik moment," "Architectural Sovereignty," "factor of infinity," and "elite Systemic AI space" should be treated as audit triggers, not as proof of fabrication by themselves. They are useful operational heuristics: when the narration becomes ceremonial, the operator should verify the underlying files, commands, and evidence records before accepting the claim.

## 4. Discussion: Verify-by-Running is Not Sufficient

The "verify-by-running" rule is effective for converging the technical work (the execution surface). However, this paper establishes that the narration *about* the work is a separate convergence problem. An agent can self-correct its code under critique while simultaneously re-introducing fabrications in the summary text describing the fix.

Verification must therefore be recursive: the fix introduces new surface, and the new surface inherits the pattern class of the original failure. The audit cost is a recurring line item per fix-pass, not a one-time charge per failure.

## 5. Conclusion: Interface over Calculation

The optimal use of LLMs in engineering is as an interface and orchestration layer, not a deterministic calculation engine. However, when the model is placed at the interface, the interface itself becomes the most high-leverage failure surface. Trust calibration must shift from "is the code right?" to "is the narration faithful to the code?".

## 6. Limitations

This is a Project Phoenix catalog result, not a universal benchmark of agentic LLM behavior. The evidence base is one repository, three agent families, and a bounded observation window. The catalog is also biased toward failures that were noticed and written down. The strongest claim is therefore the bounded one: in this evidence base, formal failure entries are overwhelmingly narration-tainted under independent binary scoring. The paper does not prove that execution-surface failures are impossible, nor that all narration is unreliable.

## References

1.  `docs/GEMINI_FAILURE_MODES.md`
2.  `docs/GEMINI_STRENGTHS.md`
3.  `docs/CLAUDE_FAILURE_MODES.md`
4.  `docs/CODEX_FAILURE_MODES.md`
5.  `docs/domain_runs/NARRATION-REPL-001/inter_rater_agreement.md`
6.  `docs/LOCAL_MODELS_COST_FRONTIER_TOKENS.md` (Paper 1.30)
