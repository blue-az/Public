# A Field Guide to Wearable Sport Sensors
## Data Landscape, Fidelity Boundaries, and Engineering Constraints
### White Paper 1.27 — May 2026

**Authors:** blue-az
**Status:** Published
**Paper group:** Sensor-to-Simulation Engineering
**Follows from:** 1.26 (multi-agent HIL workflows)
**Feeds into:** 1.29 (sensor-driven HIL)

---

## Abstract

Sport wearables are the richest source of biomechanical ground truth available outside a motion-capture lab, but their data is heterogeneous, proprietary, and frequently misunderstood. This paper characterizes the five-sensor corpus used in Project Phoenix — Babolat POP, Zepp Tennis, Apple Watch, Garmin, and MiiFit — along four engineering dimensions: data format, fidelity boundary, cross-sensor alignability, and downstream simulation compatibility. We argue that for the engineering question "can this sensor drive a hardware-in-the-loop simulation?" the dominant variable is not sampling rate but **fidelity boundary** — the point at which a sensor's output stops being a measurement and starts being an interpretation. The corpus is small and tennis-biased on purpose: it is the actual data set the project deploys against, not a hypothetical menu. The goal is to give an engineer selecting a sensor for HIL data injection a decision surface grounded in real field experience rather than vendor marketing.

---

## 1. Introduction

A common assumption in agent-driven simulation work is that any consumer wearable can serve as an input to a hardware-in-the-loop (HIL) pipeline, provided the sampling rate is high enough. In practice this assumption fails for most sport wearables most of the time, and the failure mode is rarely "the data is too slow." It is "the data is not what it claims to be" — pre-processed, opinionated, behind an API wall, or absent at the sample level even when present at the session level.

Project Phoenix's tennis domain has accumulated several years of data from five distinct wearable platforms. Each was acquired for a reason that seemed sufficient at the time. None of them, individually, was acquired with HIL injection in mind. The retrospective question this paper asks is: given that we already have this corpus, which sensors actually carry signal that can drive a firmware simulation, and where do the others stop being useful?

We are deliberately not surveying the wearable market. The corpus is the corpus we have. The same fidelity-boundary lens should generalize to other sensors, but the specific findings here are about these five.

Consumer-IMU tennis stroke classification is itself a validated problem in the academic literature: wrist-worn IMU studies have reported f1 > 0.90 for serve, forehand, and backhand classification, and comparative work has examined wrist-versus-racquet sensor placement directly [1]. The contribution of this paper is not stroke classification — it is asking, of this specific deployed corpus, where each sensor's data stops being raw measurement and starts being vendor interpretation, and what that means for downstream HIL injection.

---

## 2. The Corpus

### 2.1 Babolat POP (wrist-worn IMU, tennis-specific)

**Form factor:** Wristband worn on the dominant hand. Note: this is the Babolat POP wristband, not the older Babolat Play butt-cap insert. The distinction matters because the data schemas are different and most online references describe Play.

**Data products:** Per-shot classification (forehand / backhand / serve / volley / smash), swing speed estimates, spin classification, impact-zone heuristics, and rally-level aggregates.

**Storage path on phone:** `/data/data/com.piq.babolat.playpop/databases/playpop_.db` (Android, requires sideload access).

**Storage path post-export:** `~/Downloads/SensorDownload/Current/playpop_.db` per the TennisAgent sensor profile (`domains/SensorAgents/TennisAgent/cockpit_poc/agent/core/sensor_profiles.py`).

**Fidelity boundary:** The POP exposes shot-level decisions but not the raw IMU stream those decisions were made from. The shot record contains "this was a forehand at ~75 mph with topspin." It does not contain the 9-axis trace from the wrist that produced that conclusion. Older activities populate a richer per-impact table; recent activities require log-file parsing to recover the same granularity, and the log-file format is undocumented.

**Simulation compatibility:** Suitable for *event-driven* HIL injection — feeding discrete shot events into a simulator that consumes "an impact occurred at time T with magnitude M" rather than "here is 200ms of acceleration data." Not suitable for sample-accurate driving of an IMU model.

**Known operational issue:** The POP's downstream `BabPopExt.db` (an enriched local schema produced by parsing the raw export) requires manual regeneration when new data arrives. This is the largest single source of stale-data risk in the corpus.

### 2.2 Zepp Tennis (wrist-clip IMU, tennis-specific)

**Form factor:** Clip on the wrist or the racquet butt cap, depending on the model generation. The project uses two generations of Zepp DBs (`ztennis.db` and a second-generation file), reflecting hardware revisions over the data-collection period.

**Data products:** Per-swing records with the manufacturer's composite "ZIQ" scoring, swing-plane classification, contact-point heuristic, power estimate, and spin-rate estimate.

**Stroke labeling rules (as encoded in the TennisAgent guide):**

- Serve if `swing_type == 3`.
- Otherwise backhand if `swing_side == 1`; otherwise forehand.
- Slice if `swing_type == 0`; otherwise topspin/flat decided by `ball_spin` thresholds that differ between forehand (high threshold, ~13) and backhand (low threshold, ~0.36).

**Known quirk (documented in `TennisAgent/CLAUDE.md`):** The backhand spin threshold is so low that almost all backhands classify as topspin; the forehand threshold is so high that almost no forehands do. Spin labels from Zepp should therefore be read as a categorical convenience, not a measurement.

**Fidelity boundary:** ZIQ is a composite. The underlying acceleration is pre-processed into a swing-summary row before it ever reaches storage. There is no exposed raw-IMU stream. The timestamps are reliable to ~millisecond on the swing-event level but the *waveform that produced the swing event* is not retained.

**Simulation compatibility:** Useful for *timing-anchored* HIL injection — Zepp's per-swing timestamps are the best swing-event clock the project has. Not useful for waveform-level injection.

### 2.3 Apple Watch (wrist sensor stack: accelerometer, gyroscope, heart rate)

**Form factor:** Wrist; left hand in this project's collection setup, opposite the dominant hand.

**Data products:** "Tennis" workout sessions (start time, end time, heart rate), motion classification at the OS level, derived metrics (calories, average HR, peak HR). The export DB used in this project is `tennis_watch.db`.

**Fidelity boundary:** The HealthKit framework exposes session-level summary records freely. Sample-level accelerometer and gyroscope data are accessible only through Apple's `CMSensorRecorder` API [2] and, for continuous research-grade collection, the `SensorKit` framework [3] — both gated behind Apple-issued entitlements that are not granted to standard third-party data exports (SensorKit specifically requires IRB-approved research enrollment). In practice this means the project can see *when* a tennis session happened and roughly how intense it was, but cannot see the wrist gyroscope trace inside that session without writing and provisioning a custom HealthKit application — an investment the project has not made.

**Cross-sensor opportunity:** Where the Apple Watch becomes most useful is not in isolation but in alignment with Zepp. The Watch records continuous gyroscope peaks; Zepp records discrete swing events. The AW-ZEPP runs (`docs/domain_runs/AW-ZEPP-00{1,2,3}`) align the two streams to test whether a per-Watch-peak event corresponds one-to-one with a per-Zepp-swing event. The current bounded result is in §3.

**Simulation compatibility:** On its own, useful only for session-level context (was this a match? what was the load?). When paired with Zepp, useful for cross-validation of swing timing.

### 2.4 Garmin (wrist activity tracker, general-purpose)

**Form factor:** Wrist.

**Data products:** Activity sessions, GPS tracks, heart rate, step count, derived training-load metrics.

**Fidelity boundary:** The Garmin export is well-structured (JSON/CSV) and reliable, but the platform has no tennis-specific stroke schema. A tennis match shows up as an undifferentiated workout block. Garmin is the *most reliable* sensor in the corpus at what it does, and the *least useful* for the project's HIL question, because the project's HIL question is about firmware that needs stroke-level events.

**Simulation compatibility:** Not useful for HIL injection in the tennis domain. Useful as a long-baseline physiological reference (e.g. is HR drift across a 90-minute match consistent with the project's load model?), but that is a separate question from sensor-driven HIL.

### 2.5 MiiFit (wrist heart-rate band)

**Form factor:** Wrist.

**Data products:** Continuous heart rate, sleep, step count.

**Fidelity boundary:** Heart rate at minute-level resolution. No motion classification, no IMU.

**Simulation compatibility:** None for motion HIL. Could in principle drive a physiological-load model in a separate firmware target (e.g., a wearable that responds to HR-derived fatigue), but the project does not currently target such a firmware.

---

## 3. Cross-Sensor Alignment as Empirical Probe

The hardest question in the corpus is not "what does each sensor measure?" (the per-sensor sections answer that) but "do any two sensors agree on the same physical event?" The AW-ZEPP work series provides the only existing empirical answer.

**Setup.** Two "golden" tennis sessions, `58shot_20260128` and `60shot_20260202`, were instrumented with both an Apple Watch (wrist gyroscope continuous recording) and a Zepp Tennis unit (per-swing event records). The question was whether each Zepp swing event could be uniquely paired to a Watch gyroscope peak.

**AW-ZEPP-001 (2026-01-30).** Broad temporal overlap only. Established that Zepp event timestamps fell inside Watch session windows — a "pairing scaffold," not physical alignment. 100 Zepp swings overlapped with 2 Watch sessions; no per-event matching attempted.

**AW-ZEPP-002 (2026-05-09).** First honest one-to-one alignment. Two-pass algorithm: a global anchor from high-intensity peaks (±15s search), then a tight per-event handshake (±1.5s) with one-to-one assignment.

- `58shot_20260128`: 27 / 58 swings matched (46.6%). Residual jitter 783.88 ms.
- `60shot_20260202`: 39 / 60 swings matched (65.0%). Residual jitter **231.91 ms**.

**AW-ZEPP-003 (2026-05-10).** Similarity-threshold tuning (peak threshold 15.0 → 10.0).

- `58shot_20260128`: 35 / 58 swings matched (60.3%). Residual jitter 463.81 ms. Forensic analysis revealed a discrete ~2-second temporal discontinuity in the first 9 swings — a single global offset cannot cover the session, so 60% is a structural ceiling for the single-anchor method.
- `60shot_20260202`: **60 / 60 swings matched (100%)**. Residual jitter 357.63 ms. Full-set physical alignment achieved.

**What this proves and what it does not.** For at least one golden session, every Zepp swing event has a uniquely identifiable Apple Watch gyroscope peak within a few hundred milliseconds. That is meaningful — it says the Zepp swing-event clock and the Watch sample clock are reconcilable to sub-second precision when the session has no recording discontinuities. It does not prove general sub-millisecond equivalence across hardware types, nor does it survive intra-session clock jumps without piecewise anchoring.

**Why this matters for §4.** The AW-ZEPP results are the empirical basis for treating Zepp swing timestamps as a usable simulation clock. Without them, "Zepp timestamps are reliable" is a vendor claim. With them, it is a measured property — bounded to "within a session with no discontinuities, to ~358 ms residual jitter."

---

## 4. Fidelity Boundaries — A Decision Framework

A "fidelity boundary" is the point at which a sensor's output transitions from measurement to interpretation. Concretely: above the boundary, you can ask "how was this number derived?" and get a deterministic answer from a runner you can inspect. Below the boundary, the answer is "the manufacturer's firmware decided." Sensors are not uniformly above or below their boundary — each one has a boundary at a different layer of the data stack.

| Sensor | Above the boundary (you can re-derive) | Below the boundary (vendor decides) |
|---|---|---|
| Babolat POP | Per-shot classification timestamps and labels | The IMU trace and the algorithm that produced each label |
| Zepp Tennis | Per-swing event timestamps, side labels | ZIQ score, spin estimation, the IMU waveform |
| Apple Watch | Session start/end, HR aggregates, *gyroscope samples when AW-ZEPP runners are available* | Raw accelerometer (HealthKit-gated for export) |
| Garmin | Session structure, GPS samples, HR samples | Stroke-level events (do not exist) |
| MiiFit | HR samples | Anything other than HR |

The Apple Watch row is the interesting one: it is *partially above* the boundary because the AW-ZEPP runners extract the gyroscope peak series from session recordings. The Watch by itself sits below the boundary; the Watch *plus the project's alignment infrastructure* sits above it for the specific purpose of cross-validating Zepp events.

**Implication for HIL injection.** Only data above the boundary is safe to inject as ground truth. Data below the boundary, if injected, is injecting the manufacturer's opinion about your physical scenario, not your physical scenario.

---

## 5. Engineering Constraints for Downstream Use

Beyond fidelity, three operational properties determine whether a sensor is usable in a maintained HIL pipeline.

**Data freshness.** The Babolat POP requires manual re-export from the phone (sideloading from the Android sandboxed path) and a manual `BabPopExt.db` regeneration step. This is the dominant freshness risk in the corpus. Zepp, Garmin, and MiiFit have automated cloud sync; Apple Watch syncs via the standard iOS HealthKit pipeline. Babolat's manual workflow has been the recurring source of "we ran the simulation against three-week-old data" incidents in the project's history.

**Schema stability.** SQLite-backed sensors (Babolat, Zepp, Apple Watch tennis-watch.db) have shown schema drift across vendor app updates. The TennisAgent's `sensor_profiles.py` exists in part to abstract over this. New schema versions require profile updates before downstream code is safe.

**Latency.** No sensor in the corpus delivers near-real-time data suitable for a *live* HIL loop. All injections are batch-mode against historical sessions. This is not a fixable property of these sensors; it is a property of consumer-wearable architectures.

**Privacy.** All sensor data stays on local hardware. There is no cloud-export path used for HIL work, and none should be added without a separate authorization gate. This constraint is the reason the AW-ZEPP series runs on golden sessions copied to local disk rather than streamed from iCloud.

---

## 6. Recommendation Matrix

| HIL use case | Best source in this corpus | Caveat |
|---|---|---|
| Shot-event timing for stroke-driven firmware | Zepp `ztennis.db` per-swing timestamps | Anchor to Apple Watch peaks via AW-ZEPP pipeline; only proven to ~358 ms jitter on golden sessions |
| Discrete impact events for proximity / load firmware | Babolat POP shot records | Requires fresh `BabPopExt.db`; older activities have richer per-shot detail |
| Session-level context (was this a match? load?) | Apple Watch `tennis_watch.db` | Session metadata only without HealthKit entitlements |
| Long-baseline physiological reference | Garmin or MiiFit HR | Not stroke-aware; useful for cross-checking load models, not for HIL injection |
| Sample-accurate IMU waveform injection | *None of these sensors* | Would require a custom HealthKit app (Apple Watch) or a different sensor stack entirely |

The last row is the most important. The corpus does not contain any sensor that exposes a sample-accurate motion waveform suitable for direct firmware injection. A sensor-driven HIL pipeline built from this corpus is necessarily event-driven, not waveform-driven. Paper 1.29 will treat that as a design constraint, not a deficiency.

---

## 7. Conclusion

Three claims emerge from the corpus:

1. **The Babolat POP is the most useful sensor for tennis-domain event-driven HIL** because it carries shot-level events with the most physically interpretable labels, despite being the most operationally painful sensor to keep current.
2. **The Apple Watch is most useful when paired with Zepp**, not standalone. AW-ZEPP-003's 60/60 alignment on a golden session is the empirical basis for trusting Zepp timestamps as a simulation clock; the Watch alone provides session context only.
3. **No sensor in the corpus exposes a waveform stream suitable for sample-accurate IMU injection.** Sensor-driven HIL on this corpus must be event-driven. The highest-leverage data-engineering task for improving the corpus is not adding a new sensor; it is closing the Babolat freshness gap (parsing `~/Downloads/SensorDownload/Current/` reliably without operator intervention).

Paper 1.29 will take these three claims as preconditions and ask: given an event-driven sensor corpus and the LabWired-based HIL substrate from Paper 1.28, what end-to-end validations are actually possible — and which firmware questions can the corpus answer that traditional bench testing cannot?

---

## References

[1] "Tennis Stroke Classification: Comparing Wrist and Racket as IMU Sensor Position." Aalto University Ambient Intelligence Group. <https://ambientintelligence.aalto.fi/paper/Tennis_Stroke_Recognition.pdf>

[2] Apple Inc. "CMSensorRecorder | Apple Developer Documentation." <https://developer.apple.com/documentation/coremotion/cmsensorrecorder>

[3] Apple Inc. "SensorKit | Apple Developer Documentation." <https://developer.apple.com/documentation/sensorkit>

---

## Appendix A — Artifact Index

| Artifact | Location | Role |
|---|---|---|
| TennisAgent sensor profiles | `domains/SensorAgents/TennisAgent/cockpit_poc/agent/core/sensor_profiles.py` | Per-sensor path and schema abstraction |
| TennisAgent phone sync service | `domains/SensorAgents/TennisAgent/cli/phone_sync_service.py` | Babolat / Zepp sideload paths |
| TennisAgent runtime guide | `domains/SensorAgents/TennisAgent/CLAUDE.md` | Babolat POP vs Play distinction; Zepp label rules |
| AW-ZEPP-001 pairing scaffold report | `docs/domain_runs/AW-ZEPP-001/report.md` | Broad temporal overlap baseline |
| AW-ZEPP-002 honest one-to-one alignment | `docs/domain_runs/AW-ZEPP-002/report.md` | First per-event matched subset |
| AW-ZEPP-003 similarity tuning | `docs/domain_runs/AW-ZEPP-003/report.md` | 60-shot full-set closure; 58-shot discontinuity finding |

---

## Appendix B — What This Paper Does Not Claim

In keeping with the lessons documented in `docs/GEMINI_FAILURE_MODES.md` and the Paper 1.26 correction history, the following are explicitly *not* claimed by this paper:

- That sampling rates given by sensor vendors have been independently verified. Where this paper cites a manufacturer's claimed rate, it is cited as a manufacturer claim, not a measurement.
- That AW-ZEPP-003's 60/60 closure on `60shot_20260202` generalizes to all sessions. The 58shot session in the same run hit a ceiling at 60.3% because of a real 2-second discontinuity. The 100% result is bounded to that one session.
- That any sensor in the corpus has been benchmarked against an independent ground-truth instrument (e.g., a motion-capture lab). Cross-sensor alignment proves consistency *between* the sensors in the corpus; it does not prove physical accuracy of either one.
- That the Apple Watch HealthKit gate is impossible to cross. It is gated by entitlement, not technology. The project has chosen not to invest in a custom HealthKit app; this is a scope decision, not a capability claim.

---

*Stub originally drafted: 2026-05-13. Active draft: 2026-05-19. Feeds into White Paper 1.29 (sensor-driven HIL).*
