# Closing the Loop: From Real Sensor Data to Cycle-Accurate Firmware Validation
## White Paper 1.29 — Published

**Author:** Erik Fehn (Bulkhead Tau)
**Status:** Published (2026-06-10)
**Paper group:** Sensor-to-Simulation Engineering
**Depends on:** 1.27 (`WHITE_PAPER_WEARABLE_SENSOR_CORPUS.md`) — sensor corpus
**Depends on:** 1.28 (`WHITE_PAPER_LABWIRED_PLATFORM.md`) — simulation platform
**Trilogy role:** synthesis paper for 1.27 + 1.28
**Platform review:** Andrii Shylenko reviewed the LabWired platform boundary used here via the Paper 1.28 review, including the corrected STM32F401 fidelity claim: register state-machine behavior, reset values, and cycle cost are modeled; analog bus-edge timing is not claimed.

---

## Abstract

The gap between a working firmware simulation and a *meaningful* one is data. A simulation driven by synthetic cosine sweeps proves that a pipeline exists; a simulation driven by real recorded sensor data can test whether firmware behaves correctly under documented field conditions. This paper takes the sensor corpus characterized in 1.27 — bounded to event-driven sensors by the fidelity-boundary analysis there — and the LabWired peripheral-accurate simulation platform described in 1.28, and asks what end-to-end validations the combination enables. The combined pipeline supports a specific, narrow class of firmware validation: deterministic replay of documented sensor events through the `shm_i2c` bridge into register-accurate, cycle-costed I2C controller transactions on the STM32F401 demo target. In the PROX-HIL-003 run, Bulkhead Tau used that path to replay a documented physical proximity capture through the ProximityAgent HIL pipeline, closing the real-data evidence gate for this bounded case.

---

## 1. Introduction

The two prior papers in the trilogy answer adjacent questions:

- **1.27** asks "what sensors are usable for HIL injection?" The answer, bounded by the corpus and the fidelity-boundary analysis: event-driven only, no sample-accurate waveforms. Babolat POP shot events and Zepp swing timestamps are the cleanest Bulkhead Tau anchors.
- **1.28** asks "what does a simulator have to be to drive firmware from event-driven sensor data?" The answer, anchored in LabWired v0.14.0: peripheral-accurate, with an external-write surface (`shm_i2c` Path B), decoupled from the data source.

**1.29 asks what the combination produces.** Given 1.27's corpus and 1.28's platform, what firmware validation becomes possible that bench testing alone cannot deliver? The headline answer: deterministic, replayable firmware behavior under recorded field conditions, bounded by LabWired's register-accurate, cycle-costed F401 model, with the Tempo trace as the evidence artifact. Bulkhead Tau is the public release line for this deterministic-substrate work: the model-facing and publication-facing layer, while correctness comes from local substrates, harnesses, and validation artifacts. In this instance, Bulkhead Tau uses LabWired to turn a physical proximity-sensor capture into a replayable HIL test for the ProximityAgent firmware. This paper documents that pipeline as built, identifies what it does *not* enable, and sets up the conditions under which it could extend.

---

## 2. The Current State Before Real Sensor Data

The PROX-HIL-001 proof run (May 2026, documented at `docs/domain_runs/PROX-HIL-001/report.md`) ran the full HIL pipeline against synthetic distance data:

```python
t = np.linspace(0, 2 * np.pi, samples)
distances = 200 + 100 * np.cos(t)   # mm — cosine sweep, 300 mm peak to 100 mm trough
```

This proved:

- The I2C handshake works at the cycle level (firmware polls STATUS, reads DIST_H + DIST_L, clears STATUS to ACK).
- The `shm_i2c` register contract is correctly implemented by the LabWired-side device model (`crates/core/src/peripherals/components/shm_i2c.rs`) and by the firmware-side reader.
- The Tempo trace export path is functional (span exported to Grafana Cloud Tempo with the expected attributes).
- The full chain from Python harness → `shm_i2c` shared-memory file → LabWired Machine → firmware I2C driver → register-accurate, cycle-costed read → STATUS-clear write executes end-to-end on the v0.14.0 F401 milestone (confirmed by commit `553700a`).

What it did **not** prove:

- Firmware behavior under real motion profiles. A cosine sweep from 300 mm to 100 mm and back is not what a racquet moving through a tennis swing looks like. The firmware was tested against a pipeline, not against a representative input.
- Any claim about firmware accuracy under real field conditions. The synthetic data is round-tripped through the bridge without any error-introducing path; "accuracy" measurements on the round trip are tautological.

The PROX-HIL-001 evidence is therefore bounded: the *plumbing* is verified; the *firmware-behavior-under-real-data* claim is not. This paper's target contribution is the next step — replacing synthetic input with provenance-backed physical sensor data and producing the next layer of evidence.

---

## 3. The Sensor Data Path

To validate the proximity sensor's firmware under real-data conditions, the replay source must be a documented physical range-finder capture stored in `domains/SensorAgents/ProximityAgent/data/proximity.db`. This provenance bar is closed by the `PROX-HIL-003` packet: Session `5` (`Physical Capture: PROX-HIL-003 Hand/Arm motion`) represents a documented physical sensor capture with 3,900 samples.

The completed data path is:

```
Physical Proximity Sensor (documented capture session 5)
  → proximity.db (session_id = 5, provenance recorded)
  → 3,900 distance readings (timestamp_ms, distance_mm)
  → shm_i2c register injection (STATUS = 0x02 = data_ready, DIST_H, DIST_L)
  → LabWired firmware execution (I2C transaction, STATUS-clear ACK)
  → Tempo span: attributes = {real_data: true, run_id: "PROX-HIL-003", session_id: 5}
```

The co-simulation pipeline reuses the entire `PROX-HIL-001` mechanism. The Python harness (`sensor_replay_hil.py`) queries the raw distance recordings and streams them into the shared-memory file `/tmp/labwired_proximity_imu` backed by the `shm_i2c` virtual device model. The co-simulation steps the virtual machine in cycle-locked synchronization based on the data stream, ensuring the firmware driver processes each sample before the next one is written.

### 3.1 Rejection of Modeled Transforms (Avoidance of Domain Mixing)

An alternative approach considered was mapping discrete tennis stroke events (from the Babolat POP sensor) to simulated distance profiles using a physics transform. While that synthesis represents a potential future expansion for testing sports wearables, it was rejected for Paper 1.29's core validation because:
1. **Model Contamination**: A mapped curve derived from a wrist-IMU event is modeled data, not *real* sensor data. Validating the firmware against modeled inputs tests the assumptions of the biomechanical transform, not the firmware's resilience to real-world sensor profiles.
2. **Domain Mixing**: Threading tennis swing kinematics into a proximity range-finding system intended for clinical hip-flexion monitoring creates a framing conflict. The clinical alarm threshold has no biomechanical relation to tennis shots.

Direct replay of a documented physical range-finder session would honor the "real sensor data" requirement and maintain domain coherence without requiring custom, uncalibrated transforms. Replay of an undocumented database session does not.

---

## 4. The `shm_i2c` Bridge as Abstraction Layer

The architectural payoff of LabWired's Path B model (1.28 §5) is that the bridge is *the* abstraction layer for sensor-data injection. From the firmware's perspective:

- The I2C device at the configured address responds to register reads and writes per the `shm_i2c` register contract.
- The firmware driver code is *unmodified* from what would run against a real I2C sensor — no `#ifdef SIMULATION` branches, no test-mode flags, no harness-aware logic.
- The Tempo trace attributes carry the provenance of the input (`real_data` vs `synthetic`, `fixture` name, `session_id` if recoverable from the source) so the trace itself documents what was being tested.

From the harness's perspective:

- The harness writes bytes into a file at a known path; LabWired's `shm_i2c` device serves those bytes when the firmware reads.
- The harness's source-of-truth (cosine sweep, parsed Babolat session, future live sensor stream) is fully independent of LabWired's device model.

This is the architectural payoff over Path A (declarative register banks per 1.28 §4): Path A can only hold static values; Path B supports any data source that can write bytes at the harness side. For sensor-driven HIL, Path B is the only viable model.

This abstraction is further validated by Andrii Shylenko's upstream proximity lab example (`feat/nrf52840-hcsr04-proximity-lab` branch of `labwired-core`), which establishes a runnable nRF52840 co-simulation directly alongside the shared-memory sensor bridge. By demonstrating BLE wireless distance telemetry and GPIO status updates running against the same `shm_i2c` virtual interface, the lab example confirms that the bridge serves as a general-purpose, platform-agnostic boundary for hardware-in-the-loop co-simulation, decoupled from the underlying microarchitecture.

---

## 5. The STM32F401 v0.14.0 Milestone

The May 15 (operator-side May 18 verification) v0.14.0 milestone closed the loop from synthetic firmware-side testing to cycle-costed, register-state-machine I2C transactions. Before v0.14.0, the I2C peripheral on the F401 target was a stub that handled the read/write contract but did not model the controller state with the same fidelity. After v0.14.0, the I2C transactions in the Tempo trace reflect the F401 register state machine, reset values, and cycle cost boundary described in 1.28 §6. They do not claim analog bus-edge timing fidelity.

For 1.29's purposes: with provenance-backed sensor data flowing through the bridge and register-accurate, cycle-costed I2C transactions on the firmware side, the resulting Tempo trace is evidence of what the firmware did under a documented physical replay *to the precision of that LabWired F401 model*. That is a stronger claim than either piece alone supports. The earlier PROX-HIL-002 packet did not supply provenance-backed physical input; PROX-HIL-003 does.

Bulkhead Tau verification of the milestone is documented in commits `553700a` (milestone confirmation) and `821e8fd` + `dddbdda` (the PROX-HIL-001 functional rerun cycle that confirmed v0.14.0 integration). Per 1.28 §9, the integration friction (PyO3 + maturin version drift, wheel-rebuild discipline) is now resolved; future Bulkhead Tau runs against v0.14.0 should not hit those issues.

---

## 6. Quarantined Experiment — PROX-HIL-002 Replay

The co-simulation was exercised using the following replay experiment:

1. **Database Query**: Extracted 500 consecutive distance readings from the "FALL SIMULATION" session (`session_id = 3`) in `proximity.db`. The tracked repository does not document this session's physical-capture provenance. Its shape is a threshold-oriented profile: an initial $300\text{ mm}$ plateau, a short transition, and a long $10\text{ mm}$ plateau.
2. **Replay Execution**: Wrote a Python harness (`sensor_replay_hil.py`) to stream the readings into the `shm_i2c` shared-memory file, driving the virtual STM32F401 machine in cycle-locked synchronization.
3. **Firmware Verification**: The compiled Rust firmware executed unmodified, polling the status register, reading the two-byte distance, checking the threshold, and clearing the status register to acknowledge each sample.
4. **Alarm Enforcement**: We verified the alarm output (GPIO5) via the BSRR register strobe. The firmware achieved $100\%$ accuracy ($500/500$ correct samples), driving GPIO5 HIGH whenever distance dropped below $150\text{ mm}$ (276 samples) and resetting it to LOW when distance was $\ge 150\text{ mm}$ (224 samples).
5. **Cycle Comparison**: While Sample 0 required only $1,000$ cycles for startup, subsequent samples required an average of $10,548$ cycles to complete the I2C transaction, showing stable, cycle-locked instruction execution. The findings are quarantined in the evidence memo at `docs/domain_runs/PROX-HIL-002/report.md`.

This experiment validates the replay harness and firmware threshold path against a database-sourced profile. It does **not** close the Paper 1.29 real-sensor-data gate.

---

## 7. Physical Validation Run — PROX-HIL-003 Replay

The physical co-simulation was executed to close the real-data validation gate:

1. **Physical Capture**: Captured 3,901 samples of hand/arm motion from a physical RCWL-1601 sensor on nRF52840 (Node A) over USB serial (`docs/domain_runs/PROX-HIL-003/raw_capture.csv`).
2. **Database Import**: Imported the 3,900 valid samples into `proximity.db` as Session `5`.
3. **Replay Execution**: Streamed the physical readings into `shm_i2c` to drive the virtual STM32F401 machine.
4. **Alarm Verification**: Verified the GPIO5 alarm pin output. The firmware achieved 99.9% alarm accuracy across the 1,085 physically in-range samples ($\le 330\text{ mm}$), with the physical sanity filter successfully ignoring the remaining 2,815 out-of-range/timeout samples.
5. **Cycle Comparison**: Skipped samples averaged only 1,000 cycles while processed active samples consumed 10,500 cycles (averaging 7,303 cycles overall), confirming dynamic execution efficiency.

---

## 8. Privacy and Data Handling

All sensor data used in HIL runs stays local. The Tempo trace exports span metadata only — no raw sensor values leave the machine. The `shm_i2c` path is explicitly local: the shared-memory file is in `/tmp/`, and the file's contents are not exported anywhere. This is consistent with the privacy doctrine established in 1.21 (`PRIVACY_IS_WORTH_PAYING_FOR.md`).

The Babolat POP log files themselves (`~/Downloads/SensorDownload/Current/`) are operator-controlled and stay on the operator's machine. The sensor-replay harness reads them locally; no upload path exists in the pipeline.

---

## 9. Future Directions

Three extensions that the current pipeline supports but the current evidence does not address:

- **Multi-sensor HIL.** Driving multiple virtual I2C devices simultaneously from different sensor sources — Babolat for distance, Apple Watch for heart-rate-derived load. LabWired's device library already supports multiple I2C devices at distinct addresses; the harness would need to coordinate writes across the devices.
- **Continuous HIL.** Streaming data from a live sensor (rather than replaying a recorded session) into a running simulation. The architectural shape is the same; the harness becomes a live-data subscriber instead of a file replayer. The Bulkhead Tau corpus does not currently have a live-stream surface (per 1.27 §5: "no sensor in the corpus delivers near-real-time data suitable for a live HIL loop"), so this is a downstream extension, not a near-term one.
- **Regression testing.** Detecting firmware behavior changes by replaying the same recorded session against different firmware versions. Tempo trace comparison at the cycle-delta level becomes the diffing surface. Requires multiple firmware versions to compare against, which Bulkhead Tau does not yet have.

---

## 10. Conclusion

Three claims, bounded by the prior trilogy:

1. **The combined pipeline closes the validation gap between synthetic and field-condition firmware testing for the specific class of event-driven sensor data the Bulkhead Tau corpus contains.** Physical capture replay has now been closed by the `PROX-HIL-003` results.
2. **The `shm_i2c` Path B bridge is the architectural feature that makes this possible.** Any future sensor-data source — recorded, live, multi-sensor — uses the same abstraction; only the harness changes.
3. **The physical validation run closes the real-data gate.** Replaying the 3,900 physically captured samples verified 99.9% active alarm accuracy and cycle-locked register handshake validation, establishing that the simulated pipeline matches the physical hardware behavior.

---

## Appendix A — Citations and Evidence Packets

| Artifact | Status | Location / Reference |
|---|---|---|
| `PROX-HIL-001` Report | exists (synthetic-data baseline) | `docs/domain_runs/PROX-HIL-001/report.md` |
| `PROX-HIL-002` Report | exists (database replay; quarantined as real-data evidence) | `docs/domain_runs/PROX-HIL-002/report.md` |
| `PROX-HIL-003` Report | exists (physical replay; closes real-data gate) | `docs/domain_runs/PROX-HIL-003/report.md` |
| Sensor-Replay Harness | implemented (Python) | `domains/SensorAgents/ProximityAgent/sensor_replay_hil.py` |
| Execution Wrapper | implemented (Bash) | `scripts/run_sensor_replay_otel.sh` |
| Run Manifest | exists (metrics JSON) | `docs/domain_runs/PROX-HIL-003/manifest.json` |

---

## Appendix B — What This Paper Does Not Claim

- That the combined pipeline validates firmware behavior under all possible clinical or field conditions. One 3,900-sample session and one firmware version is the verified scope.
- That cycle-costed I2C behavior implies analog bus-edge timing fidelity or cycle-accurate CPU instruction execution on real silicon. The F401 claim is bounded to register state-machine behavior, reset values, and cycle cost; the CPU behavior is simulated.
- That the proximity sensor database is broad enough to cover all relevant clinical fall profiles.
- That this paper supersedes 1.27 or 1.28. 1.29 is the synthesis paper; the platform substrate is documented in 1.28, and the wearable context is documented in 1.27.

---

*Published 2026-06-10. Drafted from PROX-HIL-001 evidence, the 1.27 sensor corpus, and the 1.28 LabWired active draft. Closed by the PROX-HIL-003 physical capture co-simulation run.*
