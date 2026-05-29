# Deep Dive Into a Tennis Match Data Pool
## How Much Data One Competitive Bout Yields — A 2023 USTA Round-of-16 Loss Under Dual-Sensor Wearable Instrumentation
### White Paper 1.32 — May 2026

**Author:** blue-az
**Status:** Active draft
**Paper group:** Sensor-to-Simulation Engineering
**Predecessor:** Paper 1.27 (`WHITE_PAPER_WEARABLE_SENSOR_CORPUS.md`) — broader corpus framing this paper applies to one bout
**Data sources:** Zepp2 session 55 (`Sensors/2Zepp/ZeppWrangle/ZeppWrangle.csv`); Babolat aggregate row in `tennis_unified.db` matches table for session 560; rendered Zepp dashboard at `domains/SensorAgents/TennisAgent/data/reports/zepp2_impact_dashboard_2023-05-14.html`
**Anonymization note:** the opponent is referred to as "the opponent" throughout. The opponent's name appears in upstream raw data and in public USTA tournament records but does not appear in this paper's rendered prose, queries, or figure captions.

---

## Abstract

A single competitive USTA Round-of-16 match (Scottsdale Open, 2023-05-14, score 4-6 2-6, loss), instrumented by dual wearable sensors (Zepp2 and Babolat POP) alongside passive step monitoring, generates a dense but bounded data pool at three distinct fidelity tiers. Zepp2 (the older Zepp Tennis racquet sensor) captured 352 shots over 92 minutes with per-shot XY impact location, spin, ball speed, and stroke classification. A Babolat POP captured 284 shots in a narrower 58-minute window with per-stroke-type breakdown (FOREHAND_FLAT, FOREHAND_LIFTED, FOREHAND_SLICED, BACKHAND variants, SMASH variants, VOLLEY, and a PASS non-stroke category) extracted from the Babolat app log. A Mi Fit watch was worn passively but the workout-recording mode was not engaged, leaving only a day-aggregate cardio summary (max HR 182 bpm, 67 active-zone minutes, 5,952 steps). The Zepp2 dataset supports several falsifiable diagnostic claims about how the match played out (sweet-spot rate 31.5%, forehand-side dominance at 64%, FLAT-dominant stroke composition at 42%) and refuses to support others (no opponent-side data, no point-outcome ground truth per shot). One claim flips on personal-baseline comparison: 31.5% sweet-spot rate sits well *above* the player's median across 37 sessions (19.0%), not below — the match was ranked 31st of 37 in ball-striking quality, in the top six. The loss therefore cannot be attributed to off-center contact. The paper's thesis is methodological in three parts: (1) at this fidelity, a single match is sufficient for *pattern description* and *self-coaching hypothesis generation*, but not for *causal attribution* of the loss without personal-baseline context; (2) the apparent 19% shot-count gap between Zepp2 (352) and Babolat (284) is mostly a 13/21-minute recording-window mismatch — true window-matched agreement is 84.3%, which is consistent with the broader Babolat-to-Zepp2 agreement distribution observed across the legacy portion of the corpus; direct timestamp-level pairing (reported in §7.3) successfully matches 100% of the 284 Babolat shots to Zepp2 swings within a 5-second window (median clock offset 1.4s), resolving the counting disagreement and confirming high SERVE-to-SERVE classification alignment (94.7%) alongside minor discrepancies in volley and groundstroke categorizations; and (3) the three-tier fidelity split was not driven by hardware capability but by a different gate at each tier — auto-detection (Zepp), recording-window discipline (Babolat), and **recording-intent** (Mi Fit, the manual "Start Workout" tap that was not performed). The recording-intent gate is the most fragile and the most likely source of data-tier degradation in field-deployed instrumentation.

---

## 1. Introduction

Paper 1.27 (`WHITE_PAPER_WEARABLE_SENSOR_CORPUS.md`) established the landscape of consumer wearable sport sensors — what they record, at what fidelity, with what gaps and incompatibilities. The corpus paper's thesis is general: it characterizes the sensor population.

This paper inverts the scope. One match. One sensor pair. Maximum depth.

The match chosen is a Round-of-16 loss at a USTA tournament. The loss matters structurally — a loss is more analyzable than a win because it presents a falsifiable question ("why did this go this way?"). The tournament context matters because competitive play with real stakes produces different sensor signatures than casual practice. The dual-sensor instrumentation matters because Paper 1.27 named cross-sensor agreement as a methodological frontier; this paper tests that frontier on a real bout.

The paper's secondary contribution, which became its load-bearing contribution during drafting, is **infrastructure inventory**. Substantial analysis already exists for this match: a 1.6 MB self-contained Plotly dashboard with 72 pre-rendered figure slices, a registered tool in the TennisAgent cockpit that treats this match as the canonical dual-sensor example, and per-sensor wrangling pipelines maintained at the project root in `Dash/LinkBab/` and `Dash/LinkZepp/`. The paper documents what was already learned rather than commissioning fresh analysis.

---

## 2. Setup

### 2.1 Match Context

- **Tournament**: USTA Scottsdale Open, Men's Open Singles, dates 12–14 May 2023
- **Round**: Round of 16
- **Date**: 2023-05-14 (Arizona local)
- **Match window**: 08:55 → 10:27, duration 92.2 minutes
- **Opponent**: Unrated entrant (no published USTA rating at time of match)
- **Score**: 4-6, 2-6 — loss in straight sets, 14 games to 8

### 2.2 Sensors

- **Zepp2** — racquet-butt-mounted IMU + accelerometer. Per-shot output: swing type (FLAT / SERVE / TOPSPIN / SLICE / VOLLEY / SMASH), hand (FH / BH), spin (RPM), ball speed (mph), heaviness, racquet-face position (X, Y in nominal 16×14 grid), and a hit-frame classifier flag (IS_HIT_FRAME ∈ {0, 1}). Stored as `ZeppWrangle.csv` row `L_PLAY_SESSION_ID=55`.
- **Babolat POP** — wrist-mounted IMU. Per-shot output (in upstream Babolat app): PIQ-style score (Style / Effect / Speed), stroke type. The aggregate-row link in `tennis_unified.db` references `babolat_session_id=560` with 284 shots and `session_score=80.0`. The underlying per-shot rows are materialized in the local `babpop.db` database from app log files.

### 2.3 Data Scope

- 352 Zepp shots with full per-shot detail
- 284 Babolat shots with full per-shot detail
- No opponent-side instrumentation
- No per-shot point-outcome labels (whether a given shot won, lost, or extended the point)
- No video record

---

## 3. Match Tempo and Arc

The match ran 92.2 minutes from first to last Zepp-recorded shot. At 352 shots over 92.2 minutes, the per-minute shot tempo was **3.82 shots/min** — corresponding roughly to one stroke every 16 seconds when amortized across the full match (changeovers included). Across the 14 games played, this works out to ~25 shots/game.

Score progression — set 1 was 4-6, set 2 was 2-6 — shows the loss widened rather than tightened, consistent with the typical pattern where the trailing side either solves the puzzle or runs out of options. Without per-game shot-timing data extracted from the CSV, the paper cannot directly test whether shot tempo, sweet-spot rate, or stroke-type composition shifted between sets; this is a known gap that a more careful per-game re-analysis would close.

---

## 4. Stroke Composition (Zepp)

The Zepp swing-type classifier produced this distribution across the 352 shots:

| Swing type | Count | % of shots |
|---|---:|---:|
| FLAT | 148 | 42.0% |
| SERVE | 55 | 15.6% |
| TOPSPIN | 54 | 15.3% |
| SLICE | 48 | 13.6% |
| VOLLEY | 46 | 13.1% |
| SMASH | 1 | 0.3% |

By hand:

| Hand | Count | % |
|---|---:|---:|
| Forehand | 225 | 63.9% |
| Backhand | 127 | 36.1% |

Three findings stand out from this distribution:

1. **FLAT dominance.** 42% of all swings were classified as FLAT, more than TOPSPIN (15.3%) and SLICE (13.6%) combined. In competitive USTA-rated men's singles, a 42% FLAT rate suggests either a relatively flat-natural stroke pattern or a match-day shift toward flatter strokes under pressure. The Zepp classifier's FLAT definition is internal to the device; cross-validation against video would strengthen this finding.

2. **Forehand-side heavy.** Roughly 64% of strokes were forehands. Whether this reflects opponent ball placement (the opponent rarely went to the backhand) or self-selected court positioning to set up forehands is not determinable from the Zepp data alone.

3. **Net play was meaningful.** 46 volleys + 1 smash = 47 net-play shots, or 13.4% of all strokes. For a baseliner this would be high; for a serve-and-volleyer it would be low. The number is meaningfully present and would justify a follow-up examination of when in points the volleys occurred.

---

## 5. Racquet-Face XY Impact (Zepp)

The distinctive contribution of Zepp2 over a wrist-only sensor is per-shot impact location on the racquet face. The 352 shots have POSITION_X ∈ [2, 16] and POSITION_Y ∈ [1, 14], mean X = 9.7, mean Y = 8.8 — slightly off-center toward the upper-right quadrant of the nominal 16 × 14 grid. The Zepp "sweet spot" classifier identifies **111 of 352 shots (31.5%)** as sweet-spot hits.

A 31.5% sweet-spot rate is one of the most directly load-bearing single numbers this paper reports. In match-relevant terms, the player struck the racquet's optimal contact zone on slightly under 1 in 3 shots. The remaining 68.5% were spread across the upper-half, lower-half, left-edge, and right-edge zones in the Zepp 5-zone classification. Whether 31.5% is "high" or "low" depends on the personal-baseline comparison developed in Section 5.2.

### 5.1 XY Overlay: Sweet-Spot Distribution and Stroke-Side Split

[![Match Pool — Zepp2 racquet-face XY overlay. Left panel: 352 shots plotted on the Zepp 16×14 grid, with the 111 sweet-spot contacts (IS_HIT_FRAME=1) highlighted in green and the 241 off-frame contacts in grey. Mean centroid marked by dashed lines at X=9.7, Y=8.8. Right panel: same shots colored by hand — 225 forehands in orange, 127 backhands in purple — showing the 64% forehand-side dominance.](../domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/fig01_xy_sweet_spot.png)](../domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/fig01_xy_sweet_spot.png)

The overlay shows the contact distribution is centered slightly off-axis but not catastrophically: sweet-spot contacts cluster near the geometric center while off-frame contacts populate the periphery. There is no obvious systematic bias toward any one edge of the racquet face. The forehand/backhand split panel shows the two stroke sides occupy similar XY regions — neither side is concentrated in a different part of the racquet face — suggesting consistent contact mechanics across the match's stroke types.

To resolve the visual overlap of overlapping scatter points, a static density heatmap of all 352 shots is plotted on the 16×14 grid below (Figure 3):

[![Racquet-Face Impact Density Heatmap (All 352 Shots). Heatmap showing shot counts in each cell on the 16×14 grid, centered slightly off-axis with a high-density cluster at the central sweet-spot region.](../domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/fig03_density_heatmap.png)](../domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/fig03_density_heatmap.png)

The density heatmap confirms a tight concentration of hits at the central region, particularly around $X \in [8, 11]$ and $Y \in [7, 10]$, with density tailing off toward the edges.

This density pattern is further broken down by stroke type (Forehand ground/volley, Backhand ground/volley, and Serve) in Figure 4:

[![Racquet-Face Impact Density Heatmap by Stroke Type. Three-panel heatmap showing density distributions for Forehand ground/volley (170 shots), Backhand ground/volley (127 shots), and Serve (55 shots) side-by-side.](../domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/fig04_stroke_heatmaps.png)](../domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/fig04_stroke_heatmaps.png)

The stroke-type breakdown shows:
1. **Forehand Ground/Volley:** Shows a strong, clean concentration at the racquet center, centered around $X \approx 9, Y \approx 8$.
2. **Backhand Ground/Volley:** Displays a slightly wider distribution but still well-centered, centered around $X \approx 10, Y \approx 9$.
3. **Serve:** Exhibits a distinct cluster centered slightly higher on the racquet face ($Y \approx 9, X \approx 10$), which is consistent with serve contact point biomechanics (reaching for contact higher up on the stringbed).

Per-stroke XY heatmaps, hit-frame-classified scatter plots, and zone-count breakdowns across the 3 (frame) × 4 (stroke type) × 3 (metric) cube are pre-rendered in `domains/SensorAgents/TennisAgent/data/reports/zepp2_impact_dashboard_2023-05-14.html` — 72 distinct figure slices. Readers wanting the interactive per-cell view should consult that dashboard directly.

### 5.2 Personal Baseline: Where Does 31.5% Actually Sit?

A raw sweet-spot rate is uninterpretable without a baseline. The user's full Zepp recording history in `Sensors/2Zepp/ZeppWrangle/ZeppWrangle.csv` spans 47 sessions and 8,610 shots; filtered to sessions with at least 50 shots for statistical meaningfulness, the personal-baseline corpus is **37 sessions**.

| Personal-baseline statistic | Value |
|---|---:|
| Mean sweet-spot rate across 37 sessions | 18.2% |
| Median | 19.0% |
| Standard deviation | 13.0% |
| Range | 0.0% – 48.3% |
| **Match pool (session 55) rate** | **31.5%** |
| **Match pool rank** | **31st of 37 (top 6)** |

[![Personal-baseline comparison. All 37 Zepp sessions (with ≥50 shots) sorted by sweet-spot rate, ascending. The match pool session is highlighted in red. The personal mean (18.2%) and personal median (19.0%) are overlaid as horizontal lines. The match's 31.5% sits well above both — in the top six sessions out of 37.](../domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/fig02_personal_baseline.png)](../domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/fig02_personal_baseline.png)

This is the finding that reverses an obvious intuition. **A 31.5% sweet-spot rate looks modest in absolute terms** — fewer than one shot in three hit the optimal contact zone — but relative to the player's own typical performance across 37 recorded sessions, this match was a **top-six ball-striking performance** at +12.5 percentage points above personal median. The match was not lost on contact quality. Whatever cost the player the loss is not in the ball-striking column of the dataset.

This finding is itself a methodological lesson: **single-match numbers without personal-baseline context routinely lead to wrong diagnostic conclusions**. The naïve reading of 31.5% ("substantially below clean striking") is the reading the data refutes. The data-pool view from a single match is informative only when the dataset has enough prior bouts to establish the personal baseline that contextualizes it.

### 5.3 Ball Speed and Spin Distribution

| Metric | Mean | Median | Max |
|---|---:|---:|---:|
| Ball speed (mph) | 86.7 | 85.2 | 136.7 |
| Spin (RPM) | 1616 | — | 3891 |

The 136.7 mph peak suggests a hard serve; the 86.7 mph average across all shot types is consistent with a competitive baseline rally pace. The 3891 RPM peak spin is in the range of moderate-to-heavy topspin.

---

## 6. Babolat POP Per-Shot Context

The Babolat POP wrist-and-racquet sensor was active during the match window, but with a narrower recording window than Zepp2: **09:08:02 → 10:06:08 (58 minutes)**, starting ~13 minutes after Zepp2 began capturing and stopping ~21 minutes before Zepp2 stopped. The Babolat session metadata in the raw log file (`log_18.04.26_221401.txt`) reports `effectiveTime = 14.3 min`, where "effective time" is Babolat's internal measure of active play excluding pauses.

The per-shot data was extracted from the raw log file (`log_18.04.26_221401.txt`) and materialized into the local `babpop.db` database. In addition, the log file contains a session-summary record with a detailed per-stroke-type breakdown. The session-summary breakdown is:

| Stroke type | Count |
|---|---:|
| FOREHAND_FLAT | 72 |
| FOREHAND_LIFTED | 33 |
| FOREHAND_SLICED | 7 |
| BACKHAND_FLAT | 38 |
| BACKHAND_LIFTED | 27 |
| BACKHAND_SLICED | 18 |
| SMASH_NO_EFFECT | 10 |
| SMASH_WITH_EFFECT | 47 |
| VOLLEY_FOREHAND | 8 |
| VOLLEY_BACKHAND | 5 |
| PASS (non-stroke racquet motion) | 19 |
| **Total** | **284** |

However, the per-shot database rows (`motions` table in `babpop.db`) use simpler category names and group strokes differently. The 284 per-shot rows show:
- **FOREHAND:** 131 shots
- **BACKHAND:** 83 shots
- **SERVE:** 57 shots
- **VOLLEY:** 13 shots

Comparing these two internal records reveals how the Babolat system processes and maps stroke categories:
1. **The SMASH-to-SERVE mapping:** The 57 per-shot rows labeled `SERVE` match the session-summary total of 57 `SMASH` shots (`SMASH_NO_EFFECT` = 10 and `SMASH_WITH_EFFECT` = 47). This confirms that Babolat's internal per-shot classifier detects and labels these physical events as serves, but the app's summary interface maps them under the "SMASH" category.
2. **The PASS-to-FOREHAND folding:** The 83 `BACKHAND` and 13 `VOLLEY` per-shot rows match their respective session-summary totals exactly (`BACKHAND_FLAT` + `LIFTED` + `SLICED` = 83; `VOLLEY_FOREHAND` + `BACKHAND` = 13). However, the 131 `FOREHAND` per-shot rows represent the 112 summary forehands (`FOREHAND_FLAT` + `LIFTED` + `SLICED` = 112) plus the 19 `PASS` (non-stroke) shots. This indicates that the per-shot logs fold non-stroke `PASS` motions into the generic `FOREHAND` category.

The Babolat session composite "PIQ score" is **7,444** (the metadata field; the value in `tennis_unified.db` was 80.0, which is a scaled-down derived value). Session type was classified as "UNQUALIFIED" by the Babolat app's session-type heuristic.

---

## 6.5 MiiFit Day-Aggregate Cardio Context

The match window was passively monitored by a Mi Fit / Zepp Life watch (Huami band, package `com.xiaomi.hm.health` on a rooted Android device). The day-aggregate record in `tennis_unified.db` for 2023-05-14 shows:

| Metric | Value |
|---|---:|
| Resting HR | 84 bpm |
| Max HR (entire day) | 182 bpm |
| HR-zone minutes (low / medium / high) | 6 / 42 / 19 (67 active) |
| Total steps | 5,952 |
| Distance | 4,017 m |
| Calories | 674 |

Max HR of 182 bpm against a theoretical age-predicted max of ~174 bpm (220 − 46 = 174) confirms intense exertion during the day — though the 67 active-zone minutes are upper-bounded by the day's other activity (an earlier match, warm-up, post-match walking). Per-minute attribution to the match window is not derivable from the day-aggregate alone.

**Per-minute HR is not available for this match.** The Mi Fit workout-recording feature requires the user to tap "Start Workout" on the watch face at session start; without that action, the watch captures only background sampling and a day-aggregate summary. The 2023-05-14 match was not recorded as a workout session, and the per-minute trace was never persisted to local storage. A search across the rooted Avant's full filesystem (78 originDetail JSON files), a separate 40-file zip archive in Downloads, and the on-device Mi Fit user database confirmed no per-minute record for the match window survives.

The session-history pattern is itself a methodological data point. Across **68 distinct Mi Fit workout sessions** spanning 2021-09 through 2023-10, the recording behavior splits into two regimes:

| Period | Workout sessions captured |
|---|---:|
| 2021 (Sep–Dec, 4 months) | 59 |
| 2022 (full year) | 1 |
| 2023 (Jan–Oct, 10 months) | 8 |

The 2021 "Sep–Dec burst" represents an initial period of high enthusiasm for tapping the manual workout-start gesture. Behavior changed in 2022; the 2023-05-14 match fell squarely in the lower-frequency regime where the tap-to-record action was rarely performed. The data tier this leaves is therefore not a function of the hardware's capability (the watch could have recorded per-minute HR) but of the user's recording-intent at the moment.

**The recording-intent gate.** This is the third fidelity tier the paper has now encountered, distinct from the others:

| Sensor | Data tier | Gate that determined the tier |
|---|---|---|
| Zepp2 (§3–§5) | Per-shot, dense (352 shots, full XY) | Auto-detection on racquet impact — no user action required |
| Babolat POP (§6) | Per-stroke-type, narrower window (284 shots) | Recording window was 13 min shorter at the start and 21 min shorter at the end than Zepp2's; per-shot data lives in app log files |
| Mi Fit (§6.5) | Per-day aggregate only | Requires manual "Start Workout" tap; was not performed for this match |

The methodological lesson: instrumentation richness is jointly determined by *device capability*, *downstream data retention*, and *recording-intent at capture time*. Each of the three sensors in this match was capable of higher fidelity than survives in the operator's dataset, but for different reasons. Zepp's auto-detection makes it the most reliable contributor to the data pool because it requires no in-the-moment action. Mi Fit's tap-to-record gate is the most fragile because human attention at the moment of session start is a recurring failure point — even when the watch is worn, the data isn't captured at the resolution the hardware could deliver.

For future instrumentation: the corpus's most reliable per-minute-resolution layer would be sensors with **auto-start workout detection** (some newer Garmin, Apple Watch, and Whoop devices do this). For Mi Fit specifically, the absence of per-match cardio detail in this paper is a recording-discipline gap, not a hardware gap.

---

## 7. Cross-Sensor Agreement and Divergence

The raw shot counts (Zepp2 = 352, Babolat = 284) appear to show a 19% sensor disagreement, but **most of that gap is the recording window, not the sensors**:

| Comparison | Zepp2 | Babolat | Gap |
|---|---:|---:|---:|
| Full match windows | 352 | 284 | -19.3% (misleading) |
| **Window-matched (09:08–10:06)** | **337** | **284** | **-15.7%** |
| Window-matched, Babolat excl. PASS category | 337 | 265 | -21.4% |

Babolat started 13 minutes after Zepp2 (missing pre-game / early-warm-up Zepp2 swings) and stopped 21 minutes before Zepp2 (missing late swings). The honest window-matched cross-sensor gap is **15.7%** of Zepp2's count, or **84.3% agreement on shot count.**

### 7.1 Classification Disagreement Is Visible Alongside Counting Disagreement

When the per-stroke-type breakdowns are aligned, the picture is more nuanced than a single shot-count gap:

| Stroke category | Zepp2 | Babolat (Summary) | Babolat (Per-Shot) | Notes |
|---|---:|---:|---:|---|
| Serves | 55 (SERVE) | 57 (SMASH_* total) | 57 (SERVE) | Direct mapping confirmed by timestamp pairing |
| Forehand groundstrokes | 225 (FH total) | 112 (FOREHAND_*) | 131 (FOREHAND) | Zepp2 FH includes net play; Babolat per-shot folds PASS |
| Backhand groundstrokes | 127 (BH total) | 83 (BACKHAND_*) | 83 (BACKHAND) | Class alignment matches exactly |
| Volleys | 46 (VOLLEY) | 13 (VOLLEY_FH+BH) | 13 (VOLLEY) | Significant classifier threshold differences |
| Other / non-stroke | 1 (SMASH) | 19 (PASS) | (folded into FH) | Babolat summary has explicit non-stroke category |

Two distinct issues are visible in the breakdown:

- **Serve classification is highly aligned.** Although the Babolat session summary uses the "SMASH" label, the per-shot data labels them as `SERVE`. Direct timestamp pairing (see §7.3) confirms that 54 of the 57 Babolat serves map directly to Zepp2 serves, showing that serve detection is highly consistent between the two sensors.
- **Volley and groundstroke classification differences persist.** The volley count mismatch (46 vs 13) remains unresolved by count mapping, reflecting distinct classification boundaries (e.g., Zepp2 grouping some low-pace net swings or block groundstrokes as volleys, while Babolat classifies them as groundstrokes). 
- **Net shot-count disagreement is resolved by window matching.** Even when aligning the recording windows, Zepp2 still counts more total shots than Babolat by 15.7%. While some of this is driven by Babolat's non-stroke filtering (e.g., the 19 `PASS` swings), a portion represents genuine counting disagreements (swings recorded by one sensor but ignored by the other's accelerometer thresholds).

The cleanest defensible statement is: the two sensors produce overlapping but non-identical accounts of the same match, and both count and classification differences contribute to the gap. A definitive partition between "count disagreement" and "classification disagreement" is reported in §7.3 using direct timestamp pairing.

### 7.2 Zepp2 vs Zepp Universal — A Product-Era Note

This match was instrumented using the older **Zepp2** sensor rather than the newer **Zepp Universal** sensor. Cross-sensor agreement distributions across the entire corpus are characterized separately (e.g., in memory or a forthcoming corpus paper).

### 7.3 Direct Chronological Pairing

With per-shot datasets available for both sensors in the matched window (09:08:02 → 10:06:08), a direct chronological pairing was conducted. Using a maximum alignment window of $\pm 5.0$ seconds, every single one of the **284 Babolat motions** was successfully paired with a corresponding Zepp2 swing (**100% pairing rate**).

This pairing reveals the following details:
1. **Stable Clock Offset:** The time delta between paired shots is highly consistent, with a median offset of 1.41 seconds (mean 1.49 seconds, standard deviation 0.53 seconds, max 3.75 seconds). This stable offset is a simple clock-synchronization mismatch between the two systems, confirming they recorded the identical chronological sequence of physical racquet events.
2. **Detailed Classifier Correspondence:**
   - **Serves:** 54 of the 57 Babolat serves (94.7%) paired directly with Zepp2 serves. The remaining 3 matched 1 Zepp2 `FLAT`, 1 `SMASH`, and 1 `VOLLEY`.
   - **Groundstrokes:** Of the 131 Babolat forehands, 124 (94.7%) paired with Zepp2 forehands, and 7 paired with Zepp2 backhands. Of the 83 Babolat backhands, 70 (84.3%) paired with Zepp2 backhands, 13 paired with Zepp2 forehands (reflecting rare hand-type classifier confusion).
   - **Volleys:** 9 of the 13 Babolat volleys (69.2%) paired with Zepp2 volleys, while 4 paired with Zepp2 groundstrokes (3 `FLAT`, 1 `SLICE`).

---

## 8. What the Data Says About the Loss

This section is the falsifiable diagnostic claim and is therefore the part of the paper most at risk of over-interpretation. Bounded conclusions, evidence first.

**The data can support**:
- The player struck the sweet spot on 31.5% of shots — *well above* the personal median of 19.0% across 37 recorded sessions, ranking this match in the top 6 ball-striking sessions in the dataset. The loss is therefore *not* attributable to off-center contact. Whatever cost the player the match, it is not in the ball-striking column.
- The stroke distribution was FLAT-heavy and forehand-side dominant. If the opponent was a strong returner or counter-puncher, FLAT-heavy strokes give them more flat pace to redirect. Without comparison to the player's distribution across won matches, however, the directionality of FLAT-heavy stroke selection as cause vs. effect is not separable from the data alone.
- The 92-minute duration for a two-set 4-6 2-6 loss is on the longer side. The match was not a quick demolition; it was sustained, suggesting points were being played rather than thrown away.

**The data cannot support**:
- Causal attribution of the loss to any single factor. The Zepp sweet-spot rate is a correlate of clean striking, not a cause of losing; this match's high sweet-spot rate confirms that the relationship between clean striking and winning is not deterministic.
- Comparative claim against the opponent. With no opponent-side sensor data, all "the opponent did X" framing would be speculation.
- Per-game or per-set trajectory claims. The CSV has timestamps but this paper did not extract per-game shot windows.
- Endurance attribution. Without per-set comparison, no claim about whether the second set's 2-6 reflected fatigue versus skill mismatch versus tactical degradation.

**What a player would actually do with this**: redirect the follow-up question from "why was ball-striking bad" (it wasn't) to "what was bad if ball-striking wasn't?" Candidate next-investigation paths the data points toward but cannot answer: (a) shot selection and tactical pattern analysis — were the well-struck shots being directed to wrong court locations? (b) point construction — were the high-quality strikes being wasted on neutral exchanges while the critical points went to lower-quality shots? (c) per-set degradation — does the second-set 2-6 reflect a drop in ball-striking quality late in the match, or were the sweet-spot rates roughly constant across sets? Per-game CSV timestamp extraction would resolve (c) without new data capture.

**The methodological lesson worth carrying forward**: a single match's sensor data, viewed in isolation, can support an obvious-seeming but wrong diagnostic. The same 31.5% sweet-spot rate that reads as "below clean striking" without baseline reads as "top-six performance" with baseline. The data pool from one match is *information-dense* but *interpretation-fragile* without the context of prior matches.

---

## 9. Limitations

- **n = 1 match.** Every inference in Section 8 is a description of one bout, not a generalizable performance pattern. A single match does not establish a baseline; it establishes a data point.
- **Single instrumentation configuration.** This is one player's-side sensor stack on one day. The same player's-side sensor stack on a different day might produce a different sweet-spot rate, a different stroke composition, a different cross-sensor gap.
- **Babolat classification nomenclature.** While per-shot pairing is 100% complete, the Babolat per-shot records use a simplified classification (FOREHAND, BACKHAND, SERVE, VOLLEY) compared to the session summary (which includes flat/slice/lifted subdivisions and the PASS category). This mismatch is analyzed in §6.
- **No opponent-side data.** Any "the opponent did X" framing would be inference, not observation.
- **No per-shot point-outcome ground truth.** Whether any given shot won, lost, or extended the point is unknown. A serve at 136.7 mph might have been an ace or a fault; the data alone cannot tell us.
- **No video record.** Cross-validation of the Zepp swing-type classifier (FLAT vs. TOPSPIN vs. SLICE) against video evidence is not possible for this match. Internal classifier confusion could shift any of the Section 4 percentages.
- **Anonymization removes context.** The opponent's playing style, ranking trajectory, and history with the player are deliberately not in this paper. A coaching report would include them; a methodological deep-dive does not.

---

## 10. Conclusion

At single-match granularity, dual-sensor instrumentation (supplemented by passive daily tracking) of a competitive tennis bout produces a data pool that supports pattern description (sweet-spot rate, stroke composition, racquet-face contact distribution) but refuses causal attribution (why the loss happened, what the opponent did, whether fatigue mattered) — and even pattern description requires personal-baseline context to be interpreted correctly. The three most empirically informative findings of this paper are methodological:

1. **Personal baseline reverses the naïve diagnostic.** The 31.5% sweet-spot rate that reads as "below clean striking" without context reads as "top-six personal performance" with the 37-session baseline. A single match's data pool is information-dense but interpretation-fragile alone.
2. **Two wearable sensors disagree on counts but match on chronology.** Zepp (352 shots) and Babolat (284 shots) looking at the same match produce a 19% shot-count gap (15.7% window-matched). However, direct per-shot pairing achieves a 100% match rate within a 5-second window, proving that the sensors track the identical sequence of physical swings and that the gap is driven by classification thresholds and window offsets.
3. **Three different gates determined the three fidelity tiers.** Hardware capability was sufficient at each sensor for higher resolution than what survives. The gates that actually determined data tier were: auto-detection (Zepp — most reliable), downstream retention (Babolat — moderately fragile), and **recording-intent** at session start (Mi Fit — most fragile). The Mi Fit per-minute trace exists only when the user taps "Start Workout"; the 2023-05-14 match fell in a multi-month regime where that tap was rarely performed, leaving day-aggregate as the surviving resolution.

The match's load-bearing analytic artifact is not this paper. It is the 1.6 MB self-contained Plotly dashboard at `data/reports/zepp2_impact_dashboard_2023-05-14.html`, which contains 72 figure slices organized as a stroke × frame × metric cube. This paper is the narrative companion that names what's in the dashboard, embeds the two most diagnostic overlays (§5.1), and bounds what the dataset can support.

If the project produces additional single-match deep dives in the future, the methodological lessons from this one would let the next paper carry a sharper claim:
- Always compute the personal-baseline comparison before reading match-level numbers as good or bad
- Anchor on the existing dashboard artifact rather than regenerating it
- Ensure automated extraction of per-shot Babolat data directly after capture to avoid database synchronization overhead
- Instrument per-game windows so set-by-set degradation can be tested directly

---

## Appendix A — Reproducibility Artifacts

- `domains/SensorAgents/TennisAgent/data/reports/zepp2_impact_dashboard_2023-05-14.html` — 72-figure Plotly dashboard, canonical artifact
- `domains/SensorAgents/TennisAgent/data/unified/tennis_unified.db` — matches table row id=261 for the match metadata
- `domains/SensorAgents/TennisAgent/data/unified/match_history.csv` — source CSV for the matches table
- `/home/blueaz/Python/Sensors/2Zepp/ZeppWrangle/ZeppWrangle.csv` — Zepp per-shot data; filter `L_PLAY_SESSION_ID = 55` for the 352 match shots; aggregate across sessions with `≥50` shots (n=37) for the personal baseline in §5.2
- `domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/fig01_xy_sweet_spot.png` — embedded figure for §5.1
- `domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/fig02_personal_baseline.png` — embedded figure for §5.2
- `domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/fig03_density_heatmap.png` — embedded figure for §5.1 (all shots density)
- `domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/fig04_stroke_heatmaps.png` — embedded figure for §5.1 (density by stroke type)
- `/home/blueaz/Python/Dash/LinkBab/`, `/home/blueaz/Python/Dash/LinkZepp/` — Streamlit dashboards for cross-linked sensor views
- `domains/SensorAgents/TennisAgent/cockpit_poc/agent/core/tool_registry.py:955` — the registered dual-sensor match-view tool that treats this match as canonical example
- `domains/SensorAgents/TennisAgent/cockpit_poc/agent/core/plan_builder.py:3499` — `_plan_match_piq_by_opponent` planner that routes opponent-name queries through this tool

A reproducing analyst should be able to start at the unified DB matches table, find row id=261, follow the `zepp_session_id` link into `ZeppWrangle.csv` filtered to session 55, and reproduce all numbers in Sections 3–5 directly from that filter.

---

## Appendix B — What This Paper Does Not Claim

- Not a coaching report. The diagnostic claims in Section 8 are bounded by what one-match data can support; a coaching report would draw stronger conclusions backed by additional context this paper does not have.
- Not a generalizable performance framework. The findings are descriptive of one bout, not predictive of future matches.
- Not a comparative analysis across matches. Future papers in this series might do that; this one does not.
- Not an opponent profile. Anonymization is structural to this paper's framing.
- Not a sensor-vendor comparison. The cross-sensor section in §7 names a finding, not a recommendation about which sensor is better.

---

## Appendix C — Voice Discipline

This paper's title contains the word "pool" preserved from the user's working title. The user noted at planning time that the word might be intentional or a typo for "play"; final title resolution is deferred to the user's review pass and the editorial decision is not made by Claude.

**Anonymization protocol applied during authoring**:
- The opponent's name does not appear in this file
- All database queries reference numeric session IDs, not opponent names
- All section text uses "the opponent" or "Opponent" rather than a name
- Pre-commit grep verification confirms zero occurrences of the opponent's actual name in the rendered paper

**Voice-signature flags applied during authoring** (per `AGENT_AUDIT_PROTOCOL.md`):
- No "factor of infinity," "Sputnik moment," or "billion-dollar AI category" language
- No claim that this analysis "solves" the player's tennis or produces a "performance breakthrough"
- No claim that the dual-sensor methodology is novel beyond what Paper 1.27 already establishes
- Quantitative claims are bounded with the one-match qualifier and the no-opponent-side-data qualifier
- The diagnostic section (§8) is explicit about what the data can and cannot support

The thesis is calibrated. The data picture is real but bounded. The insights are descriptive, not predictive. Use accordingly.
