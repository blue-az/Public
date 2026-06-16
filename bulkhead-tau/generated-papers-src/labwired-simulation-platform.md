# LabWired: Cycle-Accurate Hardware Simulation for Embedded Sensor Systems
## White Paper 1.28 -- Published

**Status:** Published (2026-06-09)
**Paper group:** Sensor-to-Simulation Engineering
**Authors:** Erik Fehn (Bulkhead Tau); Andrii Shylenko (LabWired)
**Follows from:** 1.27 (Field Guide to Wearable Sport Sensors)
**Feeds into:** 1.29 (sensor-driven HIL)
**Gate-evidence packet:** `docs/domain_runs/LABWIRED-F401-001/`

---

## Abstract

LabWired is a Rust-based hardware-simulation platform that executes compiled firmware against a configurable virtual hardware environment. Unlike emulators that spend most of their fidelity budget on instruction-set accuracy, LabWired targets *peripheral accuracy*: for firmware validation, the instruction set is largely solved, while the bugs and the proof live at the register boundary. This paper describes LabWired's architecture as of the v0.14.0 release, the two simulation modes it supports (declarative register banks and behavioral Rust device models), and one concrete external-contribution case study -- the `shm_i2c` shared-memory bridge added to drive a Bulkhead Tau proximity-sensor HIL pipeline. The intent is not to benchmark LabWired against other simulators; it is to characterize what the platform makes possible for downstream consumers who need register-level sensor data injection into real firmware.

---

## 1. Introduction

The gap between unit tests and on-hardware bring-up is the hardest part of embedded sensor work to compress. Unit tests cover the firmware's logic at the function level; on-hardware tests catch the integration issues but require physical instruments, calibrated sensors, and an iteration loop measured in minutes. Between these, instruction-set emulators (QEMU, gem5) execute firmware against synthetic CPU models but typically lack the peripheral fidelity needed to exercise real device drivers.

LabWired occupies that gap by inverting the usual emulator priority: instead of instruction-set accuracy with simplified peripherals, it pursues peripheral accuracy with conventional CPU execution. The trade-off is deliberate. For firmware whose interesting behavior lives at the bus and register layer -- sensor reads, register-pointer state machines, handshake protocols, reset values, and controller state -- peripheral fidelity is the binding constraint. The operating philosophy is: onboard a device once, simulate it anywhere.

This paper describes LabWired's design from the perspective of a downstream consumer (Bulkhead Tau's ProximityAgent HIL pipeline) and one contribution Bulkhead Tau made upstream (the `shm_i2c` device). It does not benchmark LabWired against alternatives, nor does it claim to be a comprehensive platform documentation -- the canonical platform documentation lives in the `labwired-core` repo.

### 1.1 Bulkhead Tau's Use Case

**What Bulkhead Tau is.** Bulkhead Tau is a deterministic agent governance framework built on the open-source tau-bench foundation. It provides a policy-enforced, SOP-driven execution layer for sensor analysis and consulting domains — a structured engine room that keeps AI agent behavior verifiable and auditable. In this context, the relevant domain is ProximityAgent: a wearable sensor system for monitoring close-approach events (e.g., hip-flexion depth in physical rehabilitation), where firmware correctness under real sensor inputs is a safety concern, not just a software-quality concern. LabWired is the simulation substrate that lets Bulkhead Tau validate that firmware against documented field conditions without requiring physical hardware in every test loop.

Bulkhead Tau's sensor corpus consists of consumer-grade wearables that do not expose raw, sample-accurate motion waveforms. As established in Bulkhead Tau Paper 1.27 ("A Field Guide to Wearable Sport Sensors"), the data is inherently event-driven. This necessitates a Hardware-in-the-Loop (HIL) approach that can replay discrete sensor events with cycle-accurate fidelity into real firmware.

The ProximityAgent HIL pipeline depends on a specific shape of simulator capability: a virtual I2C device whose register state can be mutated by an *external harness* (a Python runner replaying recorded sensor events) while firmware executes against the same registers in real time. Three properties are load-bearing:

1. **Peripheral accuracy** -- the I2C transaction state machine must match real silicon closely enough that the firmware can be run *unmodified* (no `#ifdef SIMULATION` branches).
2. **External-write surface** -- the harness must be able to push samples into the device's register state from outside the simulation's CPU loop. Static register banks are insufficient for replaying dynamic sessions.
3. **Decoupling from the data source** -- the simulator's device model must be generic enough that it can be reused across different recorded sessions and modalities.

LabWired's Path B model (Section 5) satisfies these properties, providing the platform-layer bridge between the event-driven corpus of 1.27 and the register-accurate, cycle-costed firmware validation described in the still-private 1.29 draft.

---

## 2. Architecture

LabWired is described in its own architecture documentation as a *"modular execution engine designed to decouple the CPU core from the memory and peripheral bus"* (`docs/architecture.md`). The design's central decoupling is that the execution engine is generic over a `Cpu` trait, allowing different instruction-set architectures to share the same peripheral environment. In current upstream code, `Machine` is the ELF + YAML boundary: the ELF is the unmodified flash image, while the YAML is the hardware model as data. A pass therefore says something about real firmware running against a declared hardware model, not a special simulation build.

### 2.1 Crate Organization

The Cargo workspace contains roughly 20 crates. The ones relevant to a downstream consumer:

| Crate | Role |
|---|---|
| `labwired-core` | Simulation runtime, peripheral models, I2C bus, device library |
| `labwired-config` | YAML-driven system / device configuration |
| `labwired-ir` | Intermediate representation used by codegen |
| `labwired-loader` | ELF + system loader |
| `labwired-codegen` | IR code-generation, depends on `labwired-ir` + `quote` |
| `labwired-cli` | Command-line entry point (`labwired test --script ...`) |
| `labwired-python` | PyO3 bindings -- what Bulkhead Tau's Python HIL runner depends on |
| `labwired-gdbstub` | GDB Remote Serial Protocol server |
| `labwired-dap` | VS Code Debug Adapter Protocol server |

Bulkhead Tau's pipeline touches `labwired-cli` (for headless test runs) and `labwired-python` (for in-process driving from the ProximityAgent Python harness). `labwired-gdbstub` and `labwired-dap` are not part of Bulkhead Tau's current usage but are platform features worth noting because they explain part of what the platform *is*: a firmware execution environment with full debugger surface, not just a binary runner.

### 2.2 Pluggable CPU Abstraction

The `Cpu` trait surface (per `docs/architecture.md`):

```rust
pub trait Cpu {
    fn reset(&mut self, bus: &mut dyn Bus) -> SimResult<()>;
    fn step(
        &mut self,
        bus: &mut dyn Bus,
        observers: &[Arc<dyn SimulationObserver>],
        config: &SimulationConfig
    ) -> SimResult<()>;
}
```

Currently implemented for **Cortex-M (ARMv7-M, Thumb-2)** and **RISC-V (RV32I)**. The STM32F401 target Bulkhead Tau uses is a Cortex-M (ARMv7E-M class) device; the F401 demo crate (`crates/firmware-f401-demo/`) is one of several firmware demos in the workspace.

### 2.3 Peripheral Interface

Devices implement the `Peripheral` trait, which the architecture doc describes as *"the contract for Memory-Mapped I/O (MMIO) and time-based state updates"*:

```rust
pub trait Peripheral {
    fn read(&self, offset: u64) -> SimResult<u8>;
    fn write(&mut self, offset: u64, value: u8) -> SimResult<()>;
    fn tick(&mut self) -> PeripheralTickResult;
}
```

The `I2cDevice` trait at `crates/core/src/peripherals/i2c.rs:22` is the I2C-specific specialization of this surface -- what Bulkhead Tau's `shm_i2c` implements (see Section 5). It is intentionally byte-at-a-time, so the device model owns its register pointer the way the silicon device does. SPI and UART have analogous behavioral surfaces (`SpiDevice`, `UartStreamDevice`) for devices whose state cannot be represented as a static register bank. The architecture doc notes that the `Peripheral` model *"prevents race conditions where a peripheral modifies memory while the CPU is executing, ensuring strict sequential consistency"*, which is part of what makes the platform's *deterministic by construction* claim hold.

### 2.4 Configurable Fidelity

The architecture doc explicitly frames performance and fidelity as a configurable trade-off, not a fixed property:

> Cycle-accurate when correctness matters; high-MIPS host execution when iteration speed matters.

Three performance gates are documented: instruction decode cache, multi-byte bus fast-path, and batched peripheral ticking (controlled by `peripheral_tick_interval`). Setting `peripheral_tick_interval` to 1 and disabling caches "restores strict cycle-accurate behavior for time-sensitive firmware." Bulkhead Tau's HIL pipeline runs in the cycle-accurate configuration; the high-MIPS mode would be relevant for iteration-speed-bound workflows (autonomous agents executing firmware rapidly), which Bulkhead Tau does not currently exercise.

### 2.5 What This Section Does Not Cover

Out of scope here:

- The `Machine` abstraction at `crates/core/src/lib.rs:631` -- its lifecycle, configuration surface, and observer model are platform-level concerns.
- The Thumb-2 decoder's instruction coverage gaps and how they map to real-firmware compatibility.
- The hardware-validated parity story (`determinism_report_h563.json`, golden-reference pipeline) -- Bulkhead Tau is a downstream consumer of the platform; the validation methodology is the platform's claim.

This section defers the full lifecycle and validation methodology to upstream documentation; the claims above are limited to the architecture boundary Bulkhead Tau rechecked in the local upstream checkout.

---

## 3. Device Library

The `crates/core/src/peripherals/components/` module is the device library's home for reusable behavioral component models. The May 2026 Bulkhead Tau inventory saw five component entries; a June 2026 upstream review showed that the library had grown to 19 device models plus a 13-device `PeripheralKit` registry. After fetching current `origin/main`, Bulkhead Tau verified both the expanded reusable component surface and the registry at `crates/core/src/peripherals/kit/registry.rs`.

```rust
pub mod adxl345;
pub mod aht20;
pub mod bg770a;
pub mod bme280;
pub mod bmp280;
pub mod i2c_factory;
pub mod ili9341;
pub mod iolink_master;
pub mod max31855;
pub mod mpu6050;
pub mod neo6m;
pub mod ntc_thermistor;
pub mod pca9685;
pub mod pcd8544;
pub mod servo;
pub mod shm_i2c;
pub mod sn74hc165;
pub mod ssd1306;
pub mod ssd1680_tricolor_290;
pub mod uc8151d_tricolor_290;
```

| Device | File | Type | Note |
|---|---|---|---|
| ADXL345 | `adxl345.rs` | accelerometer | behavioral component |
| AHT20 | `aht20.rs` | humidity / temperature | |
| BG770A | `bg770a.rs` | UART cellular modem | `PeripheralKit`; hardware-capture-backed |
| BME280 | `bme280.rs` | environmental sensor | |
| BMP280 | `bmp280.rs` | barometric pressure | configurable address |
| ILI9341 | `ili9341.rs` | SPI display | implements `SpiDevice` |
| IO-Link master | `iolink_master.rs` | UART stream device | implements `UartStreamDevice` |
| MAX31855 | `max31855.rs` | SPI thermocouple converter | confirms SPI model support |
| MPU6050 | `mpu6050.rs` | IMU (accel + gyro) | configurable address |
| NEO-6M | `neo6m.rs` | UART GPS module | confirms UART stream support |
| NTC thermistor | `ntc_thermistor.rs` | analog-style sensor model | |
| PCA9685 | `pca9685.rs` | PWM controller | component model |
| PCD8544 | `pcd8544.rs` | SPI display | |
| Servo | `servo.rs` | servo driver models | component model |
| `ShmI2c` | `shm_i2c.rs` | shared-memory bridge | added via upstream PR #87 (commit `3e7ba90`); see Section 5 |
| SN74HC165 | `sn74hc165.rs` | SPI shift register | |
| SSD1306 | `ssd1306.rs` | display | |
| SSD1680 tricolor 2.90 | `ssd1680_tricolor_290.rs` | display | |
| UC8151D tricolor 2.90 | `uc8151d_tricolor_290.rs` | display | |
| HC-SR04 | `peripherals/hc_sr04.rs` | GPIO ultrasonic sensor | shipped GPIO device; outside `components/` |
| TMP102 | `peripherals/esp32s3/tmp102.rs` | I2C temperature sensor | attached via `type: "tmp102"` in `i2c_factory.rs` |

TMP102 should not be removed from the paper. It is not listed in `components/mod.rs`, but it is present at `crates/core/src/peripherals/esp32s3/tmp102.rs` and is attached by `type: "tmp102"` through `crates/core/src/peripherals/components/i2c_factory.rs`. The earlier Bulkhead Tau correction went too far by treating TMP102 as dropped; the correct framing is that the component library spans both reusable component modules and target-specific attachable models.

What the library's *shape* offers a downstream consumer is the load-bearing question for this paper. The next subsection answers that from Bulkhead Tau's perspective; the generic-platform framing is described in Section 2.

### 3.1 Extension Pattern -- Observed from Bulkhead Tau's Contribution

From the perspective of a downstream consumer adding a new device, the extension pattern in LabWired is well-bounded. The `shm_i2c` addition in PR #87 shows the pattern:

1. **Single trait to implement.** A new I2C device implements `I2cDevice` (`crates/core/src/peripherals/i2c.rs:22`). The trait surface is narrow enough that the entire `shm_i2c` device fits in 130 lines (per the PR's diff stat).
2. **Two-step registration.** Module declaration in `components/mod.rs`, factory string in `i2c_factory.rs`. No other build-time wiring needed for the device to be available to YAML configurations.
3. **No coupling to consumer code.** The device's semantics are defined by its `I2cDevice` implementation, not by what the consumer's harness does with it. `shm_i2c` exposes a byte-addressed file; ProximityAgent's STATUS/DIST_H/DIST_L register layout is a Bulkhead Tau contract on top of the generic surface (Section 5.3). Other consumers can define different register contracts.

This pattern is what made it possible to add a Bulkhead Tau-specific capability (external-write I2C) as a *generic* upstream contribution. The platform's contribution surface respects narrow patches; the framework does not push consumers toward in-tree forks.

The platform's broader extension philosophy -- what the catalog/onboarding pipeline does and how new CPU architectures are onboarded -- remains an upstream concern.

---

## 4. Path A -- Declarative Register Banks

Path A is declarative peripheral modeling: a YAML descriptor defines a register bank, reset values, access permissions, and timing hooks without writing custom Rust. In upstream code this is the `GenericPeripheral` implementation in `crates/core/src/peripherals/declarative.rs`; a chip attaches it with `type: "declarative"` and a descriptor path, as shown by `crates/core/tests/fixtures/test_chip_declarative.yaml`.

For Bulkhead Tau's purposes, the load-bearing distinction between Path A (declarative) and Path B (shared-memory) is:

- **Path A satisfies the "firmware reads device state" requirement.** Static register banks let firmware exercise its driver logic against a known initial state. Good for smoke tests, boot-time-initialization verification, and any test where the firmware's behavior is fully determined by initial peripheral state.
- **Path A does not satisfy the "external harness mutates device state mid-simulation" requirement** (per 1.28 Section 1.1's three load-bearing properties). Static YAML is write-once at simulation start.

Section 5's `shm_i2c` Path B model is the extension that closes that gap. Path A and Path B are complementary; they answer different questions about the firmware under test. Path A is the no-Rust onboarding path for register-bank peripherals; Path B is the behavioral Rust path (`I2cDevice`, `SpiDevice`, `UartStreamDevice`) for devices with meaningful internal state or external co-simulation surfaces.

---

## 5. Path B -- Shared-Memory Device Models: the `shm_i2c` Contribution

### 5.1 Motivation
Per Section 1.1, the binding constraint Bulkhead Tau's HIL pipeline imposes on a simulator is the *external-write surface*. The `shm_i2c` device closes this gap by using a byte-addressed shared-memory file as the device's virtual register bank. This minimal extension allows an external harness to mutate peripheral state mid-simulation without coupling LabWired to the semantics of the ProximityAgent firmware.

### 5.2 The `shm_i2c` Device

The device lives at `crates/core/src/peripherals/components/shm_i2c.rs` in `labwired-core`. The module's own docstring states the framing:

> Shared-memory I2C register bridge.
> This small device model is used by Bulkhead Tau ProximityAgent tests. The external harness mutates a byte-addressed shared-memory file while firmware accesses the same bytes through I2C register-pointer transactions.

The device's public surface is intentionally narrow. The `ShmI2c::new(address, shm_path, size)` constructor takes the I2C address, a filesystem path to the backing shared-memory file, and a size in bytes. The `I2cDevice` trait implementation handles register-pointer reads and writes against the file, with `tracing::warn!` on any file-open failure (added during upstream review to avoid silent corruption under filesystem race conditions). The implementation is lightweight (about 130 lines of Rust) and focuses exclusively on the I2C transaction layer.

### 5.3 Upstream Merge
The shared-memory bridge was submitted to the upstream `w1ne/labwired-core` repository as PR #87 and merged on 2026-05-12 (commit `3e7ba90`). During review, the abstraction was refined and renamed from `shm_imu` to `shm_i2c` to reflect its general-purpose utility. This rename was mirrored in the Bulkhead Tau integration (commit `8d9f2a1`).

### 5.4 What Bulkhead Tau Can Claim
Bulkhead Tau can claim successful upstreaming of this generic bridge and successful use in its own proximity-sensor HIL pipeline. The device stands as a proof-of-concept for the platform's accessibility for targeted external contributions.

### 5.5 The Register Contract (used by ProximityAgent)

For the ProximityAgent implementation, the generic `shm_i2c` bridge is used to enforce a specific register-level contract between the harness and the firmware:

```
0x00  STATUS   bit 1 = data ready (set by harness, cleared by firmware)
0x01  DIST_H   distance high byte
0x02  DIST_L   distance low byte
```

The external harness writes a distance sample, sets the STATUS data-ready bit, and waits. The firmware polls STATUS, reads the two-byte distance, and clears the bit to acknowledge consumption. This contract is specific to the Bulkhead Tau proximity pipeline; the `shm_i2c` device itself imposes no semantics on the byte layout, allowing other consumers to define different contracts.

---

## 6. The STM32F401 I2C Implementation

The STM32F401 demo crate (`crates/firmware-f401-demo/`) is one of several firmware demos in the LabWired workspace. The v0.14.0 release tag (2026-05-15 per the upstream tag history) is the milestone the project tracks because that release closed the loop for Bulkhead Tau's ProximityAgent HIL pipeline.

### 6.1 Bulkhead Tau-Side Verification

The v0.14.0 milestone was verified end-to-end against the ProximityAgent firmware in Bulkhead Tau's repo:

- **Bulkhead Tau commit `553700a`** (2026-05-18): *"confirm May 15 milestone -- labwired v0.14.0 HIL run clean."* The HIL pipeline ran against the new I2C implementation without modification beyond version-bumping the LabWired Python wheel.
- **Bulkhead Tau commits `821e8fd`, `dddbdda`**: the PROX-HIL-001 functional rerun cycle. The first rerun attempted to exercise the new v0.14.0 register-state-machine path and uncovered the maturin / venv targeting friction documented in Section 9.1; the second commit resolved it.
- **Bulkhead Tau commits `8d9f2a1`, `d8f968d`**: local rename and HIL-loop fix to match the upstream `shm_imu -> shm_i2c` rename from PR #87.

### 6.2 What Bulkhead Tau Can Claim From the Verification

The register-accurate, cycle-costed path runs end-to-end for the ProximityAgent firmware: an external harness writes distance bytes into the shared-memory file, the firmware's I2C driver reads them through the modeled I2C register state machine, the firmware clears the STATUS bit, and a Tempo trace is exported. The full chain operates as specified.

### 6.3 Fidelity Boundary

The F401 fidelity claim is narrow: the platform models the register state machine, reset values, and cycle cost, with SWD-validated behavior. This is not a claim of analog bus-edge timing fidelity. In the Bulkhead Tau HIL run, the ProximityAgent firmware ran unmodified under LabWired; no simulation-specific firmware branch was required. That means the modeled register and bus behavior matched the firmware driver closely enough for this HIL path. Stronger analog or electrical claims are out of scope.

The controller split is important for portability: STM32F1/F4 and STM32L4-style I2C controllers have different register layouts and bit semantics. Keeping that controller surface separate is what makes an F401-to-nRF or F401-to-L4 change a controller swap rather than a rewrite of every attached device model.

---

## 7. Extending the Library

The mechanical pattern for adding a new I2C device is described in Section 3.1 from the contributor's perspective. The `shm_i2c` path from "we need this" to "merged upstream" was:

1. **First-draft local implementation.** A `shm_imu` Rust device was implemented in a local fork against the read/write requirements of the ProximityAgent HIL pipeline. The file shape matched the existing `mpu6050.rs` and other I2C devices; the trait implementation was the only surface that mattered.
2. **Upstream review surface.** Submitted as upstream PR #87. Upstream review introduced two refinements: (a) `tracing::warn!` on file-open failures (silent corruption was the worry), and (b) renaming `shm_imu` -> `shm_i2c` because the original name implied IMU-specific semantics when the abstraction is generic. Both refinements were correct and made the contribution more reusable.
3. **Merge cycle: first-contact-to-merge under 24 hours.** Not a load-bearing platform claim -- one data point -- but a useful note for downstream consumers considering contributing. The contribution surface (small, well-bounded patches to a single device family) appears to be matched to the maintainer's review cadence.
4. **Downstream mirror.** The rename and any downstream consumers of the old name had to update locally (commits `8d9f2a1` and `d8f968d` in this repo). Cost: minutes. Worth flagging because cross-repo renames are a common contribution-friction class.

The broader component-library approach is "onboard once, simulate anywhere." New devices are framed as `PeripheralKit`s. HC-SR04 has shipped as a GPIO device; SPI and UART models are already present (`MAX31855`, `NEO-6M`, and related stream/display components), so the old Bulkhead Tau note that those buses had no generic models as of May 2026 is stale. The remaining architecture gap is symmetric declarative attach across buses. The future I2C kits to watch are `VL53L0X` and `BNO055`.

The upstream catalog-autoupdate pipeline (visible in recent commits `1bb2a44`, `d2f534c`, `883540a`, `2e90678`) appears to track onboarding-target pass rates programmatically. How the catalog relates to the component library, and whether they're the same system or distinct, is in the architecture inventory's open items.

---

## 8. Limitations and Future Work

Bulkhead Tau can observe limitations from its own consumer perspective. The corrected inventory shifts this section away from the stale "missing SPI/UART" framing and toward the remaining attach-path and co-simulation seams.

### 8.1 Per-Byte File I/O in `shm_i2c`

The `shm_i2c` device opens and reads the shared-memory file on every byte access (see the source's `read_byte` / `write_byte` methods). For Bulkhead Tau's HIL cadence (one sample per simulated I2C transaction), this is sufficient. For high-frequency simulation -- many transactions per simulated second, or many devices sharing a backing file -- this should move to the existing co-simulation shared-memory transport at `crates/core/src/cosim/shm.rs`, which uses `memmap2` for one shared mmap'd page. That is the zero-copy destination and the natural seam for real co-simulation.

### 8.2 Bus Coverage

Per the corrected upstream inventory (Section 3): I2C, SPI, UART, GPIO, display, and shared-memory models now exist. The stale May 2026 statement that SPI and UART models were absent is retired. The remaining gap is not "no SPI/UART"; it is symmetric declarative attach across buses, so declarative onboarding becomes as uniform as behavioral device attachment.

### 8.3 CPU-Architecture Coverage

The architecture doc lists Cortex-M (ARMv7-M, Thumb-2) and RISC-V (RV32I). Recent upstream activity (`b81aca3` "onboard ESP32-S3-Zero with Xtensa LX7 CPU backend") indicates active expansion. ARMv8-M (Cortex-M33, M55) for newer STM32 targets is not yet implemented as far as Bulkhead Tau can verify from the architecture doc.

### 8.4 What Bulkhead Tau Does Not Claim

This section deliberately stops at *observable* limitations. The architecture doc's own framing of trade-offs ("cycle-accurate when correctness matters; high-MIPS when iteration speed matters") suggests several axes are deliberately configurable rather than "limited" -- the platform's design philosophy may differ from a naive limitations checklist.

Items here are Bulkhead Tau's external view after the June 2026 inventory update; the canonical roadmap and the design-intent framing of trade-offs remain upstream's to maintain.

---

## 9. Integration Notes from Bulkhead Tau

Friction observed while integrating LabWired into the ProximityAgent pipeline serves as a reference for future Bulkhead Tau work and an early warning for other downstream consumers.

### 9.1 PyO3 + Maturin Version Drift
The Python bindings crate ships via `maturin`, which targets the system Python by default. Initial HIL rerun attempts failed because the wheel was installed into an incorrect environment. Resolution required explicitly setting `PYTHON_SYS_EXECUTABLE` during the build (commit `dddbdda`). Furthermore, PyO3 version drift (0.20.3) necessitated the use of `PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1` to support the project's Python 3.13.2 virtual environment (commit `821e8fd`).

### 9.2 Wheel Rebuild After Source Change

Compiled artifact caching was a secondary friction point. The pattern that failed: edit Rust source -> `pip install` the wheel -> run HIL -> observe old behavior. Cause: maturin had cached a wheel from a prior source state. Resolution: `cargo clean` before rebuilding, and verify the wheel's installation path before running the HIL loop. Downstream consumers should lock the maturin target Python version per-project and not rely on the system default.

### 9.3 The v0.14.0 Milestone -- Bulkhead Tau-Side Verification
The STM32F401 I2C milestone was achieved with LabWired v0.14.0 (2026-05-15). Bulkhead Tau verified this milestone end-to-end on 2026-05-18 (commit `553700a`), confirming that the ProximityAgent firmware executes cleanly against the register-state-machine I2C implementation without modification beyond updating the Python wheel.

## 10. Related Work

### 10.1 The Landscape Bulkhead Tau Surveyed

The simulator categories relevant to Bulkhead Tau's sensor-driven HIL question are:

- **Instruction-set emulators** (QEMU, gem5): prioritize CPU-instruction-set accuracy. Peripheral models in these systems tend to be lower-fidelity, sufficient for booting an OS but not for exercising a real device driver's I2C transaction state machine. Bulkhead Tau surveyed QEMU early; the peripheral fidelity for the firmware-driver-against-I2C-sensor case was the binding shortcoming.
- **Cycle-accurate hardware simulators** (Renode, gem5 with detailed peripheral models): higher peripheral fidelity but heavier-weight; typically focused on system-level co-simulation rather than tight unit-test-style integration with a Python test harness.
- **Logic-level simulators** (Verilator, Icarus): operate at RTL fidelity; relevant when characterizing the silicon itself but not when characterizing firmware-against-virtual-silicon.

LabWired's positioning -- peripheral-accurate, CPU-execution-conventional, debugger-equipped, configurable-fidelity -- sits at a specific spot in this landscape that matches Bulkhead Tau's needs: unit-test-style integration with hardware-validated parity at the bus level.

### 10.2 What Bulkhead Tau Cannot Claim

A side-by-side technical comparison between LabWired and the alternatives above requires platform-side expertise to be authoritative. The upstream README's *"hardware-validated parity"* claim (the H563 golden-reference pipeline) is the platform's load-bearing differentiator; this paper does not generalize beyond Bulkhead Tau's use-case fit. The defensible claim here is narrower: Bulkhead Tau needed unmodified firmware execution against register-level peripheral behavior with an external data-injection surface, and LabWired supplied that combination.

---

## 11. Conclusion

Three observations from Bulkhead Tau's integration:

1. **Peripheral accuracy is the binding constraint for sensor HIL.** Instruction-set emulators don't exercise device drivers; physical hardware iterates too slowly. LabWired's peripheral-first framing matches Bulkhead Tau's event-driven sensor corpus (Paper 1.27) without requiring firmware modifications.
2. **The contribution surface respects narrow patches.** The `shm_i2c` device -- Bulkhead Tau's only upstream contribution -- was a 130-line single-file device added in one PR, reviewed and merged within 24 hours. Generic enough to be useful beyond Bulkhead Tau; specific enough to require no scope-creep extension.
3. **The v0.14.0 F401 milestone closed the loop end-to-end.** Register-state-machine I2C against firmware-driver-unchanged code completed the simulation path Bulkhead Tau needed. Paper 1.29 will take this as a precondition.

For consumers considering LabWired: the integration experience is well-bounded once the maturin / PyO3 friction (Section 9.1) is settled. The contribution surface is matched to the maintainer's review cadence. The platform's roadmap is visible in upstream activity (catalog autoupdates, additional CPU-architecture onboarding) -- consumer decisions about long-term reliance should anchor in the upstream repo, not in this paper.

---

## Appendix A -- Verifiable Artifacts

| Claim | Verification |
|---|---|
| `shm_i2c` device exists at `crates/core/src/peripherals/components/shm_i2c.rs` | Upstream commit `3e7ba90` |
| PR #87 merged to `labwired-core/main` | Upstream branch `origin/main` contains `3e7ba90` |
| F401 v0.14.0 HIL run clean | Bulkhead Tau commit `553700a` |
| `Machine` struct at `crates/core/src/lib.rs:631` | Upstream `origin/main` |
| `I2cDevice` trait at `crates/core/src/peripherals/i2c.rs:22` | Upstream `origin/main` |
| TMP102 attach path | `crates/core/src/peripherals/esp32s3/tmp102.rs`; `i2c_factory.rs` maps `type: "tmp102"` |
| Path A canonical example | `crates/core/src/peripherals/declarative.rs`; `crates/core/tests/fixtures/test_chip_declarative.yaml` |
| Architecture inventory | `docs/domain_runs/LABWIRED-F401-001/architecture_inventory.md` |

---

## Appendix B -- What This Paper Does Not Claim

- That LabWired is more or less suitable than Renode, QEMU, or other simulators for general embedded development. The comparison is left to Section 10.
- That the `shm_i2c` register contract used by ProximityAgent (Section 5.3) is the right contract for other consumers. Other consumers can and should define their own register layouts.
- That the 24-hour merge cycle on PR #87 (Section 5.5) generalizes to all contributions. It is one data point.
- That the v0.14.0 milestone implies analog bus-edge timing fidelity on F401. The corrected claim is register state-machine behavior, reset values, and cycle cost, SWD-validated.
- That this paper is comprehensive LabWired documentation. The canonical platform documentation lives in `labwired-core`.

---

*Active draft begun 2026-05-20. Published 2026-06-09. Upstream platform claims remain bounded to fetched `labwired-core` `origin/main` file anchors and the evidence packet listed above.*
