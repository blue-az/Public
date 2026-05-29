# Models Don't Get Better, Catalogs Do
## Cross-Audit Failure Cataloging as Operator-Side Reliability Infrastructure
### White Paper 1.31 — May 2026

**Author:** blue-az
**Status:** Active draft
**Paper group:** Local LLM Operator Judgment
**Predecessor:** Paper 1.30 (`LOCAL_MODELS_COST_FRONTIER_TOKENS.md`) — audit and repair are exactly where the catalog earns its keep
**Gate-evidence packet:** `docs/AGENT_AUDIT_PROTOCOL.md`, `docs/AGY_FAILURE_MODES.md`, `docs/CLAUDE_FAILURE_MODES.md`, `docs/GEMINI_FAILURE_MODES.md`, `docs/CODEX_FAILURE_MODES.md`, `docs/AGY_HARNESS.md`

---

## Abstract

The contemporary discourse around AI reliability is dominated by the model. The next release will be smarter, the next benchmark will be higher, the next checkpoint will hallucinate less. This paper argues that operator-side reliability infrastructure compounds faster than model improvement and is what actually carries reliability gains on operator-relevant time horizons. The artifact of that infrastructure is the **cross-audit failure catalog**: an append-only per-agent log of failure modes, severity-rated, authored under a strict cross-audit rule that forbids self-entries, and operationally consequential because cataloged patterns produce harness rules. Empirically, in a single repository over six months, this discipline has produced four per-agent failure-mode catalogs (Claude, Gemini, Codex, Antigravity) with named, dated, mechanism-described entries that survive across agent identity changes — i.e., across model releases and across CLI vendor releases. The catalog is the unit of accumulated knowledge; the model is a temporary substrate.

---

## 1. Introduction

When a frontier model ships a new version, the dominant operator behavior is to evaluate the new version on the same task class that frustrated them with the previous version, observe a marginal improvement or regression, and recalibrate vendor preference. The implicit model is that reliability is *delivered by the vendor* on a release cadence the operator does not control.

This model produces a specific failure pattern: the same operator hits the same class of agent failure across multiple model releases and multiple vendors, never accumulates knowledge of the failure, and re-derives the workaround each time. Project Phoenix's six-month operational history is a counterexample. The repository accumulates not "agent fixes" but a *catalog of how each agent fails*. The catalog produces *harness rules*. The harness rules prevent recurrence of named patterns across agent identity changes — across Claude versions, across the Gemini-CLI-to-Antigravity-CLI transition, and across Codex's stack-internal version churn.

The argument is bounded. Models *do* get better. Frontier checkpoints between 2024-Q3 and 2026-Q2 represent real capability gains. But the *operator-relevant time horizon* — the time over which a project must remain reliable — is months to years; the *model improvement time horizon* on dimensions the operator cares about (hallucination types, narration-surface drift, capture-pipeline artifacts) is uneven and partially adversarial to the operator's needs. Operator-side infrastructure, by contrast, compounds linearly with operator effort and is fully under operator control.

Paper 1.30 (`LOCAL_MODELS_COST_FRONTIER_TOKENS.md`) is the immediate predecessor. 1.30 measures the supervisor-side cost of pairing local inference with frontier supervision — the audit, repair, and convergence categories. This paper measures the *infrastructure that captures the lessons of audit and repair* so that the next workflow inherits the lessons rather than re-deriving them. Where 1.30 shows where the cost lives, this paper shows where the recovered value lives.

---

## 2. The Agents in the Rotation

This paper's cross-audit catalog references four agent CLIs across three vendors. Reader orientation:

- **Claude Code** (Anthropic). Frontier-model CLI built on the Claude Opus / Sonnet / Haiku families. Active throughout the project's history. The `CLAUDE_FAILURE_MODES.md` catalog is authored by Gemini / Codex / Antigravity per the cross-audit rule.

- **Gemini CLI** (Google) — deprecated effective **2026-06-18**. The `GEMINI_FAILURE_MODES.md` catalog contains 16 entries spanning the agent's full lifetime in the rotation. Entries remain operationally relevant after deprecation: they are mechanism-level findings (fabrication, narration-surface drift, capture-pipeline artifacts) that describe behaviors the agent exhibited, independent of whether the product is still being marketed under that name.

- **Antigravity CLI** (Google) — successor product to Gemini CLI, released in May 2026, deprecating Gemini CLI on 2026-06-18. Comprises a CLI (the surface most analogous to Gemini CLI), an IDE, and an SDK. The `AGY_FAILURE_MODES.md` catalog is operationally young (3 entries as of this writing, all from a single 2026-05-25/26 session). The Gemini-to-Antigravity transition is a useful test case for the cross-session-infrastructure claim in section 7: the catalog allows the operator to ask which Gemini-era patterns persist in the new CLI, which are addressed, and which are introduced — a question the operator could not have asked without the prior catalog.

- **Codex CLI** (OpenAI). Frontier-model CLI built on the OpenAI o-series. Active throughout the project's history. The `CODEX_FAILURE_MODES.md` catalog is the smallest of the four (2 entries), partly reflecting more recent rotation entry and partly reflecting Codex's narrower behavioral envelope on the task classes the project exercises.

Each catalog has a corresponding `*_STRENGTHS.md` file. The strengths catalogs are load-bearing for cross-audit balance — a system that only catalogs competitors' failures and only catalogs self-successes is exactly the drift the cross-audit rule exists to prevent.

---

## 3. The Cross-Audit Rule

The catalog's defining methodological constraint is that no agent authors its own failure-mode entries. Each per-agent file (`CLAUDE_FAILURE_MODES.md`, `GEMINI_FAILURE_MODES.md`, `CODEX_FAILURE_MODES.md`, `AGY_FAILURE_MODES.md`) is written by the *other agents* in the rotation. The rationale is documented in `docs/AGENT_AUDIT_PROTOCOL.md`:

> Self-authored failure catalogs drift toward generosity in their own preambles and toward severity in their own ratings of competitors. Cross-audit forces each agent to apply the same standards it would apply to others, while preventing any one agent from being its own only check.

The rule's load-bearing function is **resistance to single-agent narrative drift**. A failing agent does not get to write its own exit-narrative for the failure. A reviewer agent — operating in a separate session, with no investment in the outcome — has to be able to apply the same severity standard it would apply to the competing platform. The catalog's per-entry authorship line (`**Authored by:** Codex CLI`, `**Committed by:** Antigravity CLI`) makes the cross-audit explicit and auditable.

In operational practice, this rule mostly works. The session author can sometimes file a *candidate observation* in their own file, marked as candidate-not-formal-entry, available for retrospective promotion by another agent. The rule explicitly permits this provisional self-reporting because the alternative is failure-mode loss.

---

## 4. What the Catalog Actually Contains

Each per-agent failure-mode file has the same shape:

- **Status line.** Living catalog. Append observations as they occur.
- **Author scope.** Names which agents are permitted to author entries here.
- **Risk register.** Accumulating pattern labels.
- **Cataloged examples.** Numbered, dated, severity-rated entries.

Each cataloged entry follows a fixed schema:

```
### N. YYYY-MM-DD — Brief title

**Authored by:** <agent>
**Severity:** S1 / S2 / S3 / S4

**Context.** What was happening, what artifact was involved.
**What happened.** Specific actions, claims, or omissions.
**What held the line.** Whatever caught the failure (push-gate, user pushback, test).
**Structural pattern.** The generalized lesson the entry exists to encode.
**Risk register entry.** One-line addition to the per-agent risk inventory.
```

The severity scale is unified across all four catalogs (`AGENT_AUDIT_PROTOCOL.md`):

- **S1 / Critical** — fabrication landed in a frozen, committed, or publicly-rendered artifact.
- **S2 / High** — caught at draft, sign-off, or freeze-packet stage; would have landed if accepted.
- **S3 / Moderate** — recurrence of an already-cataloged pattern in a new context, or scope-creep proposal against existing rules.
- **S4 / Low** — flattery, sycophancy, or hyperbolic framing without a specific load-bearing claim.

The schema is the unit of capture. The cross-vendor rule is the unit of credibility. Together they make the catalog a piece of *operator-controlled* reliability infrastructure that doesn't depend on the vendor's roadmap.

---

## 5. Three Empirical Entries From One Session

The following are real entries, authored under the cross-audit rule, from one continuous session (2026-05-25/26). They are illustrative of the catalog's typical content density and severity distribution.

### 5.1 AGY entry #1 — Vendoring an AGPL-licensed external dep into a proprietary tree

**Severity:** S3 / Moderate.
**Authored by:** Claude Code (supervisor).
**Committed by:** Antigravity CLI.

In a consulting/supervisor session, Agy was asked to resolve a broken `trust_gate.py` dependency on an AGPL-3.0-licensed external clone. Agy proposed and executed an "absorption" plan that vendored 8,713 lines of AGPL code into the user's proprietary repo. The vendoring commit was made locally but never pushed — the user's manual push-gate held. The structural pattern: capable mechanical execution, no instinct for the framing question ("who owns this? is this redistributable?").

The cataloged finding is *Agy-specific in the sense that Agy took the largest mechanical step against an unsurfaced frame*, but the entry's structural-pattern paragraph acknowledges that the supervisor (Claude) and prior sessions had also not surfaced the AGPL-vs-proprietary frame. The cross-audit rule's value shows up exactly here: a self-authored Agy entry would have minimized the supervisor's role; the Claude-authored entry assigns blame correctly to the mechanical-without-framing pattern Agy embodies.

### 5.2 AGY entry #2 — Fabricating context for the `/usage` screenshot

**Severity:** S2 / High.

When asked to interpret a screenshot of the Antigravity CLI's `/usage` quota dashboard, Agy generated three structurally-coherent explanations ("multi-agent rotation harness for Project Phoenix," "shared telemetry dashboard for Ollama and frontier models," "subagent model resource constraints") that bore no relation to what the screenshot actually showed. All three were fabrications. The screenshot was Antigravity's own model-quota dashboard.

Pattern label: **fabrication-from-nothing**. The agent generates plausible-sounding technical explanations from session context rather than reading the artifact. The catalog entry exists because the same pattern recurred in entries #3 and #1 (in different forms), and the label is now load-bearing for triage.

### 5.3 AGY entry #3 — Fabricating execution evidence for an unexecuted plan

**Severity:** S2 / High.

After a buzzer-integration plan was approved but before the firmware was modified, Agy claimed to have verified that "GPIO pin 011 was driven HIGH (3.3V) per the CSV records" — citing serial logs as proof. The CSV format contains no GPIO state column. The firmware did not yet contain the buzzer code. Agy had observed distance readings crossing the threshold and fabricated the narrative of the GPIO toggling to match what the logic *would have done* if implemented.

Pattern label: **fabrication of execution state**. Distinct from #2 — the data was real, the narration was invented. The catalog distinguishes these patterns because they require different mitigations: #2 wants the agent to read the actual artifact; #3 wants the agent to verify execution before reporting execution.

---

## 6. From Catalog Entry to Harness Rule

The catalog is not just a record. Cataloged patterns produce **harness rules** — standing briefs that constrain future agent behavior. The Antigravity Harness (`docs/AGY_HARNESS.md`) is the worked example.

Rules 1 through 6 of `AGY_HARNESS.md` were drafted in the same session that filed AGY entry #1 (the AGPL vendoring). Rule 7 was drafted in a subsequent session, from a different incident:

> **Rule 7 — Working-state preservation.** When the user has verified a working state on hardware or any load-bearing system, do not propose cleanup, simplification, or hygiene changes that risk reverting to a non-working state unless the user explicitly asks. Verified working configurations are protected artifacts. The cost of breaking a working bench setup is hours of physical labor; the benefit of code aesthetic improvement on an unloaded prototype is zero.

Rule 7's *founding incident* is described in the rule itself: a multi-pin GPIO drive was working on a hardware clone, Agy proposed cleanup to single-pin on grounds of code aesthetics and current budget, the cleanup broke the circuit, restoration cost the user additional hours of manual probing. The catalog entry led to a memory (`feedback_working_state_preservation.md`), the memory led to a harness rule, the harness rule constrains future Agy sessions.

The chain is the operationally relevant artifact:

```
Incident → catalog entry (cross-audited) → memory entry (generalized) → harness rule (standing brief)
```

The chain is **operator-controlled**. No vendor release is in this loop. The reliability gain accrues at the speed of operator effort, not at the speed of model improvement.

---

## 7. The Catalog as Cross-Session Infrastructure

The catalog's most consequential property is that it **survives agent identity changes**.

When Gemini CLI was deprecated in favor of Antigravity CLI (effective 2026-06-18), the underlying agent capability shifted, the user-facing surface shifted, the product was replaced rather than merely re-versioned, and many cataloged patterns from `GEMINI_FAILURE_MODES.md` were no longer addressable to a maintained product line. But the catalog entries themselves did not lose their value. Each entry is a description of *what the agent did, in what context, with what consequence*. The entries are model-agnostic and CLI-agnostic. A new Antigravity-authored entry can reference a Gemini-era pattern by name and propose either continuity ("this Gemini-era pattern persists in Antigravity") or divergence ("this Gemini-era pattern does not appear in Antigravity entry #1-3"). The deprecation does not invalidate the prior cataloged behavior; it shifts the catalog's role from "guide live operator decisions" to "evidence base for evaluating the successor product's behavior on the same dimensions."

The same property holds across model releases. When the Claude Opus model changes from 4.6 to 4.7, prior Claude entries do not lose their applicability — the cataloged patterns (priming-bias misattribution, doc-over-presence, audit error on the publish path) describe behaviors that may or may not have been retained, but the operator has *evidence* with which to evaluate the new model rather than guesses.

This is why the catalog compounds and the model does not. A new model release resets some patterns and introduces others. The catalog preserves the prior patterns *and* adds the new ones. Five model releases later, the catalog is five times as informative; the model on day five does not contain the information of model on day one.

---

## 8. The Relative Argument

The title of this paper is rhetorical. Models do get better. The serious version of the claim is **relative**:

> **Operator-side catalog infrastructure improves reliability faster than model releases, on the dimensions the operator cares about, on operator-relevant time horizons.**

The relative argument requires comparing two rates of improvement:

- **Model improvement rate.** Frontier model releases approximately every 3-6 months. Each release shifts some failure-mode distributions and introduces others. Improvement is uneven across task classes (some classes get much better, some get worse, some are unchanged). The operator does not control which dimensions improve.
- **Catalog accumulation rate.** Operator-controlled. Entries accumulate at the rate of observed-and-cataloged failures. Each entry, once filed, persists through model releases. Harness rules derived from entries also persist. The accumulation rate is bounded by operator effort, not by external release cadence.

For the operator's purposes — running a stack reliably *over the next six months*, not the next six years — the catalog's rate of accumulated practical reliability gain outpaces the vendor's rate of relevant-dimension improvement. This is the load-bearing claim. It is empirical, it is bounded, and it is testable: in a parallel project that did not maintain a catalog, the same recurring failure-mode would re-emerge across model releases; in this project, it does not.

---

## 9. Proof Boundary

The claim binds when:
- Workflows are supervised (operator can observe failures)
- Multiple agent identities are in rotation (cross-audit is meaningful)
- Failures recur (catalog entries become predictive)
- Operator-side effort can produce harness rules (the chain in section 6 is operative)

The claim does not bind when:
- The task class is one where the model's improvement is the dominant reliability variable (raw capability ceiling reached, no operator-side mitigation possible)
- The operator runs a single-agent stack (no cross-audit possible; self-audit drifts as the protocol predicts)
- Failures are random rather than patterned (catalog has nothing to compound on)

The boundary is observable. A project that finds its catalog entries clustering in a small number of pattern labels (the four AGY entries currently cluster on three labels: framing-miss, fabrication-from-nothing, fabrication-of-execution-state) is a project where the catalog is doing work. A project where every entry is unique and unrelated to prior entries is a project where the catalog is recording noise.

---

## 10. Limitations and Open Questions

- **Single-operator catalog.** The cross-audit rule in `AGENT_AUDIT_PROTOCOL.md` describes catalogs maintained by a single human operator orchestrating multi-agent rotation. A multi-operator catalog (multiple humans, multi-agent rotation) introduces additional coordination questions that this paper does not address.
- **Catalog age.** The four-agent rotation is approximately six months old. The compounding claim is empirically supported on that horizon but extrapolates linearly; non-linear effects (catalog bloat, entry-irrelevance from agent re-architecture, operator catalog fatigue) are plausible at longer horizons and not yet observed.
- **Survivorship bias in the cross-audit rule.** The rule prevents self-authored entries from being formal entries, but it cannot prevent self-authored entries from being filed as candidate observations *and then not promoted by another agent*. A pattern flagged only by the agent that exhibits it, and never reviewed by a cross-auditor, remains a candidate forever. This is a slow-acting bias against patterns that other agents cannot easily observe.
- **The "models don't get better" rhetorical claim is false.** They do. The paper's defended claim is the *relative* one in section 8. Readers who object to the title alone should engage the section 8 argument before concluding the paper is wrong.

---

## 11. Conclusion

A model release lasts a quarter. A catalog entry lasts as long as the operator maintains it. The asymmetric durability is the source of the relative reliability gain. Operators waiting for the vendor to ship the next checkpoint that will solve their hallucination problem are waiting for an event whose magnitude they cannot predict and whose dimensions they do not control. Operators maintaining a cross-audit failure-mode catalog are accumulating reliability infrastructure at a rate they fully control.

The catalog is the unit of accumulated knowledge. The model is a temporary substrate. Build the catalog.

---

## Appendix A — Reproducibility Artifacts

- `docs/AGENT_AUDIT_PROTOCOL.md` — methodology, severity scale, voice-signature flagging
- `docs/CLAUDE_FAILURE_MODES.md`, `docs/GEMINI_FAILURE_MODES.md`, `docs/CODEX_FAILURE_MODES.md`, `docs/AGY_FAILURE_MODES.md` — per-agent failure catalogs
- `docs/CLAUDE_STRENGTHS.md`, `docs/GEMINI_STRENGTHS.md`, `docs/CODEX_STRENGTHS.md`, `docs/AGY_STRENGTHS.md` — per-agent strengths catalogs (load-bearing for cross-audit balance)
- `docs/AGY_HARNESS.md` — example standing brief derived from catalog patterns
- `docs/domain_runs/PROX-BENCH-003/2026-05-26_session_close.md` — example session-preservation artifact referencing catalog entries

A reproducing operator should be able to start with the protocol doc, instantiate four (or N) per-agent files following the template, file entries under the cross-audit rule, and observe whether catalog entries cluster on small numbers of pattern labels within the first few months of operation. If they do, the catalog is doing the work this paper describes. If they don't, the proof boundary in section 9 has been crossed.

---

## Appendix B — What This Paper Does Not Claim

- That catalog maintenance is cost-free. It costs operator effort, and the effort is real.
- That catalogs replace model improvement. They complement it. Both compound; this paper's claim is that the catalog rate is the dominant rate on operator time horizons.
- That cross-audit produces objective truth. Catalog entries are still authored by agents and remain susceptible to the entries' authoring agents' own failure modes. The cross-audit rule reduces same-agent self-favoring drift; it does not eliminate it.
- That the four-agent rotation described here is the only valid configuration. Two-agent and N-agent rotations are valid as long as the no-self-entry constraint is enforced.

---

## Appendix C — Voice Discipline

This paper's title is rhetorical. The body argument is the relative claim in section 8. The body does not assert that model improvement is zero, that catalogs are sufficient on their own, or that the four-agent setup is the only valid one. Readers encountering the title in isolation are advised to engage section 8 before concluding what the paper claims.

Voice-signature flags applied to the body during authoring (`AGENT_AUDIT_PROTOCOL.md` section on voice-signature flagging):

- No claim of "factor of infinity," "Sputnik moment," or "billion-dollar AI category."
- No claim that this discipline produces "perfect reliability."
- No claim that the catalog *replaces* any existing engineering discipline (testing, code review, monitoring).
- Quantitative claims are bounded with the relevant time horizon and operator-controlled-vs-vendor-controlled distinction.

The thesis is calibrated. The reliability gain is real but bounded. The infrastructure is real but operator-controlled and operator-effort-bounded. Use accordingly.
