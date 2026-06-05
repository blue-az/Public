# Trust the Validator, Not the Model: Deterministic Quality Gates in Bounded Domain Building under Bulkhead Tau

## 1. Executive Summary

As enterprise AI adoption transitions from conversational aids to autonomous software engineers, the reliance on model-side reasoning presents a structural liability. In the Bulkhead τ (Project Phoenix) architecture, we posit that the safety and efficacy of an agentic workflow is not guaranteed by the intelligence of the underlying model, but rather by the rigidity of the deterministic quality gates that govern it.

This paper presents the findings of the **Domain Build Benchmark 002 (DBB-002)**, contrasting a frontier model via the Gemini CLI against two tiered local models (Gemma 4 26B and Gemma 3 27B). The empirical evidence demonstrates that "silent path violations"—where models write syntactically correct code into incorrect or unauthorized directory structures—appear as a salient local-model failure mode. We conclude that robust agentic systems must treat the model as an untrusted generation substrate and offload safety, pathing, and semantic enforcement entirely to deterministic Phase 2 validation loops.

## 2. The Architecture of Bulkhead τ Verification

Bulkhead τ operates on a "Trust the Validator" paradigm. Rather than instructing a model to "be careful" or relying on system prompts for path enforcement, the framework employs an execution environment where:
1. **Isolated Witness Boundaries:** Agents operate within segregated OS user spaces with cryptographic identity enforcement.
2. **Phase 2 Hardened Validation:** Compile success is insufficient. Automated validators enforce file presence, exact output format schemas, and structural directory adherence.
3. **Automated Repair Loops:** When a model violates a Phase 2 gate, the deterministic failure log is piped back as context, forcing the model to self-correct within the established boundaries.

## 3. Empirical Evidence: DBB-002 (WaterReportAgent)

The DBB-002 benchmark evaluated the implementation of a multi-table lookup scenario. The performance divergence across the three models illustrates the necessity of externalized validation.

*(The following analysis is derived from the canonical artifact: `docs/domain_runs/DBB-002/matrix_summary.md`)*

### DBB-002 Comparison Matrix

| Path | First-Pass Validity | Final Quality | Repair Loops | Supervision Interventions | Verdict |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **gemini_cli** | `PASS` | `PASS` | 0 | 0 | **PASS** |
| **gemma4_local** (26b) | `PARTIAL` | `PASS` | 1 | 0 | **PASS** |
| **gemma3_local** (27b) | `PARTIAL` | `PASS` | 1 | 1 | **PASS** |

### 3.1 The Frontier Baseline: Zero-Repair Execution
The `gemini_cli` (backed by a frontier model) passed the DBB-002 packet with zero repairs and zero supervision. It accurately navigated the directory structure and generated perfectly conforming JSON schemas on the first pass.

### 3.2 The Capable Local Model: Automated Self-Repair
The `gemma4_local` model achieved a `PASS` verdict, but required **1 automated repair loop**. It initially failed a Phase 2 format check, but successfully corrected itself when the deterministic validation failure was fed back into its context window. This demonstrates the viability of "cheap" local reasoning when coupled with a robust, automated repair mechanism.

### 3.3 The Brittle Local Model: Silent Path Violations
The `gemma3_local` model resulted in a `PASS`, exposing the core liability of local generation. It required **1 automated repair** and **1 manual supervision intervention**. Crucially, it committed a **Silent Path Violation**, writing structurally correct code into `domains/ExperimentalAgents/p0/` instead of the requested `domains/ExperimentalAgents/WaterReportAgent/p0/` directory. Without the Phase 2 path validator explicitly flagging the missing file, the run would have been mistakenly logged as a success.

## 4. Glossary of Key Terms

To contextualize this analysis:
*   **Silent Path Violation**: A failure mode where the model writes syntactically correct code but places files in the wrong directory, making the model believe it succeeded when it actually broke the system structure.
*   **Phase 2 Hardened Validation**: Strictly enforced, automated checks that verify not just compile success, but file paths, file presence, and exact output format schemas.
*   **Repair Loop**: An automated feedback cycle where validator failure logs are fed back to the model to allow it to self-correct without human coding.
*   **Supervision Intervention**: Manual action required by a human operator or supervising harness to resolve format errors (e.g., extracting code from a malformed markdown response).
*   **P0 Workflows / Artifacts**: The minimal, initial set of user-facing operations that a newly built domain must prove it can execute.

## 5. Conclusion

The results of DBB-002 firmly establish that relying on model intelligence for structural compliance is a false economy. As models scale down for local inference (e.g., Gemma 3/4), their capacity to hold complex directory and schema constraints degrades before their capacity to write functional logic.

By externalizing these constraints into deterministic, zero-trust quality gates, organizations can safely leverage cheaper, privacy-preserving local models. Under the Bulkhead τ framework, the model is permitted to fail; it is the validator that ensures the system succeeds.
