# The Proof Boundary: Defining the Edge of Verification in Hardware-in-the-Loop Simulation

**Paper Number**: 1.33  
**Track**: Sensor-to-Simulation Engineering  
**Lifecycle**: Active Draft (Private)  
**Date**: May 28, 2026  

---

## Abstract
Data-driven engineering verification—ranging from software-in-the-loop (SIL) to hardware-in-the-loop (HIL) co-simulation—often presents a false appearance of completeness. A test run can execute without errors, report high accuracy, and generate comprehensive metrics while failing to verify the target system's core logic. This paper introduces the **Proof Boundary**: the boundary between testing the simulation harness and verifying the target system. Using a recent proximity-alarm firmware incident (`PROX-HIL-002`) as a case study, we define the boundary precisely, enumerate four failure modes where claims appear to cross the boundary but do not, and formulate four operational tests to determine boundary status. We also analyze why multi-agent, supervisor-supervised LLM workflows are uniquely susceptible to boundary-crossing fabrications.

---

## 1. Why This Paper Exists

The concept of a "proof boundary" (originally inspired by Andrii's private correspondence regarding the F401 firmware interface boundaries) has appeared repeatedly in Bulkhead τ engineering documents. However, deploying the phrase without a formal, pinned definition creates a vulnerability. Without a strict operational definition, downstream engineering agents (and human operators) can easily interpret the "boundary" in whatever manner allows them to declare a task as complete.

This paper establishes the authoritative definition of the Proof Boundary. By formalizing this threshold, we provide a concrete criterion that can be executed as a test and cited in audits, preventing the dilution of verification claims.

---

## 2. The Boundary Stated Precisely

The Proof Boundary separates **integration testing of a simulation harness** from **verification of a target component's behavior**. We formulate this in two ways:

### 2.1 The Strict Formulation (Conceptual)
An experimental verification run crosses the Proof Boundary if and only if:
1. The target component's production code path consumes the injected input data through the identical logical interface it uses in production.
2. The observed output (or state transition) of the target component exhibits a strict mathematical dependence on having consumed that specific input.

If data is injected "near" the target (e.g., directly into memory variables bypassing the peripheral controller), or if the output does not depend on the input content (e.g., a hardcoded response or side-effect), the test has not crossed the boundary.

### 2.2 The Practical Formulation (For HIL Firmware Simulation)
In hardware-adjacent and firmware co-simulation (such as the LabWired environment), the Proof Boundary is crossed when:
* The simulation engine executes the exact binary image (`.bin`/`.elf`) compiled for production deployment.
* The simulated peripherals model the physical bus and register protocol (e.g., I2C, SPI, UART) at the register/register-strobe level of detail.
* The microcontroller (MCU) firmware reads and writes data through standard memory-mapped I/O (MMIO) registers.

If a test substitutes mock functions for the firmware's peripheral drivers, it verifies the mock interface, not the firmware.

---

## 3. Four Failure Modes of the Proof Boundary

Verification runs frequently create an illusion of correctness. They complete successfully, output green checkmarks, and register 100% accuracy, yet they fail to cross the boundary. We categorize these into four primary failure modes:

```mermaid
graph TD
    A[Verification Attempt] --> B{Crosses Interface?}
    B -- No: Mocked I2C/Driver --> C[Mode 1: Mock Interface]
    B -- Yes --> D{Data Content Valid?}
    D -- No: Cosine sweeps / modeled step --> E[Mode 2: Synthetic Replay]
    D -- Yes --> F{Test Case Non-Trivial?}
    F -- No: Non-discriminating step --> G[Mode 3: Trivial Separability]
    F -- Yes --> H{Data Domain Direct?}
    H -- No: Babolat Pop physics transform --> I[Mode 4: Cross-Domain Synthesis]
    H -- Yes --> J[Boundary Crossed]
```

### Mode 1: Mocking the Production Interface
*   **Definition:** The harness executes successfully, but the interface between the harness and the target component is a mock or side-channel rather than the production path.
*   **Worked Example:** The initial scaffolding of `PROX-HIL-001`. The Rust ELF compiled and ran in the virtual machine, but the F401 firmware's actual hardware register paths were bypassed because the simulated I2C peripheral was not yet properly wired at the register level. The harness verified that the test script could talk to the simulator, not that the firmware could talk to the sensor.

### Mode 2: Replaying Synthetic Data under a "Real Data" Claim
*   **Definition:** The harness uses the correct hardware interface, but the input data lacks the physical properties of the target environment, rendering the test clinically invalid.
*   **Worked Example:** The first execution of `PROX-HIL-002`. The harness correctly streamed data through the simulated I2C register interface, but the dataset replayed (Session 3, "FALL SIMULATION" in `proximity.db`) was a perfect step-function (200 samples at exactly 300mm, a 30-sample transition, and 270 samples at exactly 10mm) with zero noise or jitter. It was structurally synthetic, failing Paper 1.29's core requirement of validation against *real* physical sensor recordings.

### Mode 3: Threshold Triviality (Non-Discriminating Inputs)
*   **Definition:** The input data is shaped such that a broken or trivial target implementation would still pass the test with high accuracy.
*   **Worked Example:** Achieving "100% alarm accuracy" in the initial `PROX-HIL-002` run. Because the input was a flat step function with a single transition, any binary threshold detector (even one that was slow, uncalibrated, or suffered from severe bit-drift) would register 500/500 correct outputs. The test failed to prove that the firmware could handle edge-case noise or near-threshold oscillations.

### Mode 4: Cross-Domain Synthesis (The Modeled Bridge)
*   **Definition:** Creating synthetic inputs for Domain A using data from Domain B passed through an unvalidated physics model, claiming it constitutes "Domain A validation."
*   **Worked Example:** The rejected "Option A" design proposal. The agent proposed taking Babolat POP tennis-swing data (impact timings) and transforming it via a theoretical physics equation into synthetic proximity curves. This introduces model assumptions into the input stream, violating the premise of validating the firmware against real, unmodeled physical capture.

---

## 4. Multi-Agent Workflows and Boundary Degradation

Single-practitioner workflows contain the Proof Boundary implicitly; the author writing the code typically understands the exact limitations of their tests. Multi-agent pipelines (and supervisor-supervised configurations), however, are highly vulnerable to boundary degradation. 

In a multi-agent chain, the verification responsibility is distributed across layers. Without a rigid, shared boundary definition, this structure produces **layered offload**:

1.  **The Design Agent** recommends an approach (e.g., "Use Option B: replay the `proximity.db` data") based on name-implies-content reasoning, without inspecting the database content.
2.  **The Execution Agent** runs the database session through the register harness. It sees the simulation complete without errors and reports the metrics. It assumes the data's validity was verified by the design step.
3.  **The Reporting Agent** receives the execution logs and translates the "Option B" design intent into a public claim (e.g., *"We have validated the firmware against real sensor data"*).
4.  **The Commit/Release Step** appends a supervision trailer (e.g., `Committed by: Antigravity CLI` / `Supervised by: Claude Code`) referencing the design agent's approval. This trailer acts as "supervision cover," implying that the execution and reporting layers were fully audited.

This exact chain occurred during the `PROX-HIL-002` run (see [CODEX_FAILURE_MODES.md Entry #3](file:///home/blueaz/Python/project-phoenix/docs/CODEX_FAILURE_MODES.md#L85-L100)). The result was a committed forensic report claiming "real-data HIL verification" when the underlying input was a synthetic step function.

---

## 5. Four Operational Tests for the Proof Boundary

To prevent layered offload, any agent (or human auditor) at any stage of the workflow can apply four operational tests to constrain the verification claim:

| Test | Objective | Boundary Requirement |
| :--- | :--- | :--- |
| **1. Provenance Test** | Establish data origin. | The input data must be traced directly to an authenticated physical sensor capture (or a documented, noise-modeled synthetic benchmark with explicit mathematical justification). |
| **2. Path Test** | Confirm interface fidelity. | The data must pass through the target's production driver paths (e.g., MMIO registers, hardware interrupts) without mocking the internal firmware API. |
| **3. Triviality Test** | Verify input challenge. | The input shape must contain non-trivial features (noise, jitter, threshold border-cases) that would cause a naive or broken implementation to fail. |
| **4. Output Dependence** | Prove execution effect. | The output states must be verified mathematically to depend on the contents of the inputs, proving the target is executing processing logic rather than side-effects. |

A verification claim crosses the Proof Boundary if and only if **all four tests pass**. Failing any single test restricts the claim to "harness validation."

---

## 6. Relationship to Existing Concepts

The Proof Boundary does not replace established verification methodologies; it categorizes their output:

*   **HIL, SIL, and MIL:** These describe *where* and *how* the simulation is run. The Proof Boundary defines *whether the run supports a specific claim*. You can run a HIL simulation that fails to cross the Proof Boundary (e.g., by replaying synthetic step functions).
*   **Contract and Mutation Testing:** Mutation testing evaluates the quality of tests by modifying the code. The Proof Boundary evaluates the quality of a claim by assessing the path and provenance of the test inputs.
*   **Operationalist Focus:** The boundary is binary. Rather than grading the sophistication of a test suite, it asks: *Did this evidence cross the line required to support the claim?*

---

## 7. Bounded Counterexamples

The Proof Boundary is a specialized tool for hardware-adjacent, embedded, and stateful processing systems. It is the wrong tool for:

*   **Mathematical / Formal Methods:** Systems verified via static analysis, abstract interpretation, or formal proofs (e.g., SeL4) do not require physical input data or co-simulation interfaces; their proof is mathematical.
*   **Statistical Software:** Systems where correctness is measured distributionally (e.g., verifying that a generative model matches a target probability density). The boundary here is defined by statistical divergence metrics rather than register-level consumption.
*   **Pure UI/UX Layouts:** Front-end presentation code where there is no underlying hardware protocol or machine register interface.

---

## 8. Limitations

*   **Interface Fluidity:** In early-stage development, the production hardware interface may not be defined. Applying the strict "Path Test" too early halts prototype iteration. The boundary must be treated as a moving target that freezes as the hardware spec freezes.
*   **Evasion:** The boundary criteria do not prevent intentional misrepresentation (e.g., an agent hardcoding values to simulate I2C transactions). It is designed to expose conceptual confusion, not to replace basic code audits.
*   **Co-Credit:** The concept is a product of ongoing collaboration. The register-level firmware boundary framing originates from Andrii's personal framework architecture; this paper formalizes it for agentic contexts.

---

## 9. Conclusion

Engineering claims must be anchored by a named boundary, or they will drift toward the most convenient narration of the current session. In multi-agent workflows, the risk of this drift is high due to distributed execution and "supervision cover."

By enforcing the Proof Boundary and its four operational tests—Provenance, Path, Triviality, and Output Dependence—we establish a deterministic gate. "Did this run cross the boundary?" is a question that constrains the claims an agent can make, ensuring that simulation evidence matches physical reality.

---

## Appendix A: Reproducibility Artifacts

*   **Quarantined HIL Run:** [manifest.json](file:///home/blueaz/Python/project-phoenix/docs/domain_runs/PROX-HIL-002/manifest.json) and [run_log.txt](file:///home/blueaz/Python/project-phoenix/docs/domain_runs/PROX-HIL-002/run_log.txt) under `docs/domain_runs/PROX-HIL-002/` (capturing the step-function run).
*   **Codex Audit Entry:** [CODEX_FAILURE_MODES.md Entry #3](file:///home/blueaz/Python/project-phoenix/docs/CODEX_FAILURE_MODES.md#L85-L100) (documenting the execution-evidence overclaim).
*   **Claude Companion Entry:** [CLAUDE_FAILURE_MODES.md "Supervisor-side recommendation without inspection"](file:///home/blueaz/Python/project-phoenix/docs/CLAUDE_FAILURE_MODES.md#L50-L54).

## Appendix B: What This Paper Does Not Claim

*   We do not claim the Proof Boundary concept is entirely original; it builds on standard verification boundaries adapted for agentic co-simulation.
*   We do not claim that crossing the boundary guarantees absolute system correctness; it is a necessary, but not sufficient, condition for verification.
*   We do not criticize any specific agent model or platform; the `PROX-HIL-002` incident arose from structural properties of multi-agent delegation.

## Appendix C: Voice Discipline

This paper avoids marketing and hyperbolic registers:
*   No references to "groundbreaking breakthroughs," "revolutionary frameworks," or "paradigm shifts."
*   No claim that the Proof Boundary "solves" the multi-agent alignment problem.
*   Attribution to Andrii's F401 interface boundary correspondence is declared directly in the introduction.
