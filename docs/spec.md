# Wattalizer – Technical Specification v1.2

## Changelog

- **v1.2** (2026-03-04): Multi-platform support (iOS, Android, macOS, Windows, Linux). Responsive layout with compact/medium/expanded breakpoints. Keyboard shortcuts for desktop. Device connection adapts to dialog on wide layouts. Updated tech stack (universal_ble replaces flutter_reactive_ble).
- **v1.0**: Initial specification — iOS and Android mobile app.

---

## 1. Overview

### 1.1 Purpose
A cross-platform application (mobile & desktop) for track cyclists and sprint athletes to analyze power output during sprint interval training sessions. The app connects to BLE power meters, automatically detects sprint efforts, computes Maximum Average Power (MAP) curves per effort, and tracks personal records over time.

### 1.2 Target Users
Track cyclists, sprint specialists, and coaches performing high-intensity interval sessions on the track or stationary trainer. The primary use case is repeated short-duration maximal efforts (3–30 seconds) with recovery between efforts.

### 1.3 Key Features
- Real-time MAP curve (1–90s) per detected effort
- Automatic sprint effort detection via delta-based power analysis
- Per-effort and per-session analysis with historical comparison
- All-time Power Duration Curve (personal records per duration)
- Session effort overlay (see fatigue across intervals)
- Historical best/worst envelope behind live curve
- TCX import/export for interoperability with Strava, Garmin Connect, etc.
- Dual-sided power meter support (L/R balance, individual leg power)
- Focus mode for mid-sprint glanceability
- Responsive layout: mobile portrait/landscape, desktop side-by-side with keyboard shortcuts

### 1.4 Technology Stack
- Framework: Flutter (Dart) — single codebase for iOS, Android, macOS, Windows, Linux
- State Management: Riverpod
- BLE: universal_ble (cross-platform BLE including desktop)
- Database: SQLite via Drift (formerly Moor)
- Charts: fl_chart
- Export/Import: Custom TCX serializer/parser (XML)
- Persistence: path_provider for file system access

---

## 2. Architecture

### 2.1 Layered Architecture

```
lib/
  core/          — shared utilities, constants, error types
  data/          — BLE, database, file I/O, TCX serialization
  domain/        — business logic, models, computations
  presentation/  — screens, widgets, Riverpod providers
```

Dependency rule: Presentation → Domain → Data interfaces. Data implements domain interfaces. No layer references the layer above it.

### 2.2 Data Layer
- **BleServiceImpl** — wraps universal_ble, manages scanning, connection state machine, characteristic subscriptions
- **Profile Parsers** — stateless byte-to-typed-data parsers for Cycling Power (0x1818), Heart Rate (0x180D), Cycling Speed & Cadence (0x1816)
- **LocalRideRepository** — Drift/SQLite implementation of the RideRepository interface
- **TcxSerializer / TcxParser** — XML serialization for import/export

### 2.3 Domain Layer
- **Models** — pure Dart classes (SensorReading, Ride, Effort, MapCurve, etc.)
- **RideSessionManager** — orchestrates active rides, accumulates readings, manages 1Hz merge
- **AutoLapDetector** — delta-based effort detection state machine
- **EffortManager** — creates/ends efforts, handles manual laps
- **MapCurveCalculator** — prefix sum computation with monotonicity enforcement
- **HistoricalRangeCalculator** — best/worst envelopes with provenance from cached curves (single pass; best envelope = PDC)
- **SummaryCalculator** — ride and effort summary statistics
- **ExportService** — domain model to export format transformation

### 2.4 Presentation Layer
- **Riverpod Providers** — reactive state management connecting domain logic to UI
- **Screens** — Ride (primary), History, Ride Detail, Power Duration Curve, Device Connection, Settings
- **Layout** — responsive: compact (mobile/narrow window), medium (tablet/medium window with nav rail), expanded (wide window with focus+chart side-by-side)

### 2.5 Provider Graph

| Provider | Depends On | Exposes |
|---|---|---|
| bleConnectionProvider | BleService interface | connection state, discovered devices |
| sensorStreamProvider | BleService interface | Stream\<SensorReading\> |
| rideSessionProvider | sensorStreamProvider, RideRepository | ride state, live readings |
| activeEffortProvider | EffortManager, MapCurveCalculator | current effort MAP, effort state |
| sessionEffortsProvider | EffortManager | previous efforts' MAP curves |
| historicalRangeProvider | RideRepository (getAllEffortCurves), HistoricalRangeCalculator, spanSelectionProvider, tagFilterProvider | HistoricalRange: best/worst envelopes with provenance (best = PDC) |
| rideListProvider | RideRepository, spanSelectionProvider, tagFilterProvider | past rides filtered by span and tags |
| spanSelectionProvider | — | selected HistorySpan (single source of truth) |
| tagFilterProvider | — | selected tag filters (empty = show all) |
| autoLapConfigProvider | RideRepository | current AutoLapConfig |
| maxPowerProvider | RideRepository (settings + historicalRange allTime best[0]) | max power for % of record display |

---

## 3. BLE Communication Layer

### 3.1 Supported Services

| Service | UUID | Data |
|---|---|---|
| Cycling Power | 0x1818 | Power, L/R balance, crank revolutions, torque, pedal angles |
| Heart Rate | 0x180D | Heart rate (BPM), RR-intervals |
| Cycling Speed & Cadence | 0x1816 | Crank revolutions, wheel revolutions |

### 3.2 Connection State Machine

States: Disconnected → Connecting → Discovering Services → Subscribing → Connected → Reconnecting

- On link drop during a ride: automatic reconnection with exponential backoff (1s, 2s, 4s, 8s… capped at 30s)
- After 2 minutes of failed reconnection: transition to Disconnected
- Reconnection is silent — no user-facing dialogs, only a subtle status indicator
- Null readings recorded during dropout (sensor dropout ≠ zero power)

### 3.3 Profile Parsers

**Power Parser** (Cycling Power Measurement, 0x2A63):
- Variable-length structure: 2-byte flags field determines which optional fields follow
- Fields parsed in order: instantaneous power (s16, always present), pedal balance (u8), accumulated torque (u16), wheel revolution data (u32 + u16), crank revolution data (u16 + u16), extreme force magnitudes (s16 + s16), extreme torque magnitudes (s16 + s16), extreme angles (u12 + u12 packed into u24), top/bottom dead spot angles (u16 + u16), accumulated energy (u16)
- All values little-endian
- Stateless parser — pure function from bytes to PowerData

**HR Parser** (Heart Rate Measurement, 0x2A37):
- Flags byte bit 0: HR format (0 = u8, 1 = u16)
- Optional RR-intervals as list of u16 values (1/1024s resolution)
- Stateless parser

**CSC Parser** (CSC Measurement, 0x2A5B):
- Stateful — requires previous reading to compute cadence from delta
- Cumulative crank revolutions (u16) + last crank event time (u16, 1/1024s)
- Cadence RPM = (revs₂ - revs₁) / (time₂ - time₁) × 60
- Must handle 16-bit counter rollover (65535 → 0)
- First reading returns null cadence
- Reset on reconnection to avoid bogus deltas

### 3.4 1Hz Merge Strategy

Raw BLE notifications arrive at sensor's native rate (typically 1–4 Hz). RideSessionManager accumulates readings into 1-second bins:
- Power: average all readings within the bin
- Heart rate: last value in bin
- Cadence: last value in bin
- No data in bin: null (gap)

Merged readings are stored and used for MAP calculation.

### 3.5 Remembered Devices

Stored in database: device ID, display name, supported services, last connected, autoconnect flag.
- On ride start: attempt auto-connect to remembered devices
- Timeout after 5 seconds → show scan screen
- User can rename devices, toggle auto-connect, forget devices

### 3.6 Test Fixtures for Parsers
- Primary: Hand-constructed byte arrays from Bluetooth SIG specification covering all flag combinations
- Secondary: Captured from BLE simulators (Zwack, you-gatt-me)
- Regression: Captured from real hardware during development (added per device tested)

---

## 4. Data Models

### 4.1 SensorReading

The fundamental unit of recorded data. One per second.

| Field | Type | Notes |
|---|---|---|
| timestamp | Duration | Offset from ride start |
| power | double? | Watts, nullable (dropout) |
| leftRightBalance | double? | Left leg %, 0–100 |
| leftPower | double? | Watts |
| rightPower | double? | Watts |
| heartRate | int? | BPM |
| cadence | double? | RPM (fractional from delta calc) |
| crankTorque | double? | Nm |
| accumulatedTorque | int? | Raw accumulated value |
| crankRevolutions | int? | Raw cumulative count |
| lastCrankEventTime | int? | Raw 1/1024s timestamp |
| maxForceMagnitude | int? | Newtons |
| minForceMagnitude | int? | Newtons |
| maxTorqueMagnitude | int? | Nm × 32 |
| minTorqueMagnitude | int? | Nm × 32 |
| topDeadSpotAngle | int? | Degrees |
| bottomDeadSpotAngle | int? | Degrees |
| accumulatedEnergy | int? | kJ |
| rrIntervals | List\<int\>? | Milliseconds |

All sensor fields are nullable. Null means sensor dropout, not zero. Zero is valid data (e.g., coasting). Raw intermediate fields (accumulatedTorque, crankRevolutions, lastCrankEventTime, force/torque magnitudes, dead spot angles, accumulatedEnergy, rrIntervals) are stored for TCX export and future analysis (pedal stroke, HRV) even though they are not used by the app's own UI in v1.

### 4.2 Ride

| Field | Type | Notes |
|---|---|---|
| id | String | UUID, generated at ride start |
| startTime | DateTime | Absolute, with timezone. Displayed in local time format. |
| endTime | DateTime? | Null while ride is active |
| tags | List\<String\> | Free-form user tags (e.g., "track", "outdoor", "trainer"). Used for filtering. |
| notes | String? | User annotations |
| source | RideSource | recorded \| imported_tcx |
| autoLapConfigId | String? | Config used for effort detection |
| efforts | List\<Effort\> | Detected sprint efforts |
| summary | RideSummary | Precomputed aggregates |

Note: `readings` are NOT a field on Ride. They are always lazy-loaded separately via `RideRepository.getReadings()` due to their size (thousands of rows). Ride objects returned from list queries and detail queries never contain readings in memory.

Note: Ride-level PDC (best power at each duration across the session) is NOT a field on Ride. It is a derived value computed on demand by taking `max(effort.curve[d])` across all efforts. This computation lives in the presentation/provider layer, not the model.

### 4.3 Effort

| Field | Type | Notes |
|---|---|---|
| id | String | UUID |
| rideId | String | Parent ride |
| effortNumber | int | 1-based order within ride |
| startOffset | int | Seconds from ride start |
| endOffset | int | Seconds from ride start |
| type | EffortType | auto \| manual |
| summary | EffortSummary | Precomputed aggregates |
| mapCurve | MapCurve | Per-effort MAP (90 values) |

Efforts reference ride readings by offset range — no data duplication.

### 4.4 RideSummary

| Field | Type | Notes |
|---|---|---|
| durationSeconds | int | Total ride duration (start to end) |
| activeDurationSeconds | int | Sum of effort durations only |
| avgPower | double | Average power across active efforts only (recovery excluded) |
| maxPower | double | Highest single 1Hz reading across entire ride |
| avgHeartRate | int? | Average across active efforts only |
| maxHeartRate | int? | Max across entire ride |
| avgCadence | double? | Average across active efforts only |
| totalKilojoules | double | Sum of effort kJ only (avgPower × activeDuration / 1000) |
| avgLeftRightBalance | double? | Average across active efforts only |
| readingCount | int | Total readings in ride |
| effortCount | int | |

### 4.5 EffortSummary

| Field | Type | Notes |
|---|---|---|
| durationSeconds | int | |
| avgPower | double | |
| peakPower | double | Highest single 1Hz reading in this effort |
| avgHeartRate | int? | |
| maxHeartRate | int? | |
| avgCadence | double? | |
| totalKilojoules | double | avgPower × duration / 1000 |
| avgLeftRightBalance | double? | |
| restSincePrevious | int? | Seconds since prior effort ended |

Note: `peakPower` is the single highest 1Hz power reading. There is no separate `maxPower` field — for a single effort, peak and max are the same thing. At the ride level (RideSummary), `maxPower` is the highest single reading across the entire ride.

### 4.6 MapCurve

| Field | Type | Notes |
|---|---|---|
| entityId | String | Effort ID |
| values | List\<double\> | 90 values, index 0 = 1s best |
| flags | List\<MapCurveFlags\> | 90 flags, one per duration (see below) |
| computedAt | DateTime | For cache invalidation |

Always monotonically non-increasing (enforced after computation).

**MapCurveFlags** (per duration):

| Field | Type | Notes |
|---|---|---|
| hadNulls | bool | The best window for this duration contained one or more null readings (denominator < window size) |
| wasEnforced | bool | This value was bumped up by monotonicity enforcement (original computed value was lower than the next longer duration) |

Both flags default to false. They are informational only — they do not affect the stored value. The UI uses these to display a subtle indicator (e.g., a small marker or dimmed styling) so the rider knows the value isn't purely from clean data.

UI treatment for flagged values:
- On MAP curve charts: flagged points rendered with a dashed or dimmed style instead of solid
- On key duration stat cards (1s, 5s, 10s, 30s): small asterisk or icon next to the value
- On tooltip/detail view: text explanation, e.g., "Based on partial data (sensor dropout)" or "Adjusted for consistency"
- Values with neither flag set have no indicator — this is the normal case

### 4.7 HistoricalRange

| Field | Type | Notes |
|---|---|---|
| span | HistorySpan | |
| best | List\<DurationRecord\> | 90 records with provenance (= PDC for this span) |
| worst | List\<DurationRecord\> | 90 records with provenance |
| effortCount | int | |

**DurationRecord** (per duration):

| Field | Type | Notes |
|---|---|---|
| durationSeconds | int | 1–90 |
| power | double | Best or worst average power for this duration |
| effortId | String | Source effort that produced this value |
| rideId | String | Parent ride of the source effort |
| rideDate | DateTime | Start time of the parent ride |
| effortNumber | int | Effort number within the parent ride |

Both best and worst envelopes have full provenance, enabling drill-down from any point to its source effort. Both are monotonically non-increasing. When monotonicity enforcement bumps a value, the provenance is inherited from the longer duration that provided the higher/lower value.

The best envelope serves as the PDC for the selected span. Computed on demand from cached effort-level MapCurves with provenance — not persisted.

### 4.8 DeviceInfo

| Field | Type |
|---|---|
| deviceId | String |
| displayName | String |
| supportedServices | Set\<SensorType\> |
| lastConnected | DateTime |
| autoConnect | bool |

---

## 5. Database Schema

### 5.1 Technology
SQLite via Drift. Type-safe Dart table definitions, auto-generated queries, incremental migration system.

### 5.2 Tables

**rides**

| Column | Type | Constraints |
|---|---|---|
| id | TEXT | PK |
| startTime | DATETIME | INDEX DESC |
| endTime | DATETIME | NULLABLE |
| notes | TEXT | NULLABLE |
| source | TEXT | 'recorded' or 'imported_tcx' |
| autoLapConfigId | TEXT | FK → autolap_config, NULLABLE |
| durationSeconds | INTEGER | Total ride duration |
| activeDurationSeconds | INTEGER | Sum of effort durations |
| avgPower | REAL | Avg over active efforts only |
| maxPower | REAL | Max single reading, entire ride |
| avgHeartRate | INTEGER | NULLABLE, avg over active efforts |
| maxHeartRate | INTEGER | NULLABLE, max entire ride |
| avgCadence | REAL | NULLABLE, avg over active efforts |
| totalKilojoules | REAL | Active efforts only |
| avgLeftRightBalance | REAL | NULLABLE, active efforts only |
| readingCount | INTEGER | |
| effortCount | INTEGER | |

**ride_tags**

| Column | Type | Constraints |
|---|---|---|
| rideId | TEXT | COMPOSITE PK (rideId, tag), FK → rides |
| tag | TEXT | Lowercase, trimmed |

Tags are normalized to lowercase and trimmed on write. The tag list for suggestions is derived by `SELECT tag, COUNT(*) as cnt FROM ride_tags GROUP BY tag ORDER BY cnt DESC`, returning most frequently used tags first.

**efforts**

| Column | Type | Constraints |
|---|---|---|
| id | TEXT | PK |
| rideId | TEXT | FK → rides, INDEX |
| effortNumber | INTEGER | 1-based |
| startOffset | INTEGER | seconds |
| endOffset | INTEGER | seconds |
| type | TEXT | 'auto' or 'manual' |
| durationSeconds | INTEGER | |
| avgPower | REAL | |
| peakPower | REAL | Highest single 1Hz reading |
| avgHeartRate | INTEGER | NULLABLE |
| maxHeartRate | INTEGER | NULLABLE |
| avgCadence | REAL | NULLABLE |
| totalKilojoules | REAL | |
| avgLeftRightBalance | REAL | NULLABLE |
| restSincePrevious | INTEGER | NULLABLE |

**readings**

| Column | Type | Constraints |
|---|---|---|
| id | INTEGER | PK AUTO-INCREMENT |
| rideId | TEXT | FK → rides, COMPOSITE INDEX (rideId, offsetSeconds) |
| offsetSeconds | INTEGER | |
| power | REAL | NULLABLE |
| leftRightBalance | REAL | NULLABLE |
| leftPower | REAL | NULLABLE |
| rightPower | REAL | NULLABLE |
| heartRate | INTEGER | NULLABLE |
| cadence | REAL | NULLABLE |
| crankTorque | REAL | NULLABLE |
| accumulatedTorque | INTEGER | NULLABLE |
| crankRevolutions | INTEGER | NULLABLE |
| lastCrankEventTime | INTEGER | NULLABLE |
| maxForceMagnitude | INTEGER | NULLABLE |
| minForceMagnitude | INTEGER | NULLABLE |
| maxTorqueMagnitude | INTEGER | NULLABLE |
| minTorqueMagnitude | INTEGER | NULLABLE |
| topDeadSpotAngle | INTEGER | NULLABLE |
| bottomDeadSpotAngle | INTEGER | NULLABLE |
| accumulatedEnergy | INTEGER | NULLABLE |
| rrIntervals | TEXT | NULLABLE, JSON list |

**map_curves** (per effort)

| Column | Type | Constraints |
|---|---|---|
| effortId | TEXT | COMPOSITE PK (effortId, durationSeconds), FK → efforts |
| durationSeconds | INTEGER | 1–90 |
| bestAvgPower | REAL | |
| hadNulls | BOOLEAN | DEFAULT FALSE |
| wasEnforced | BOOLEAN | DEFAULT FALSE |

**autolap_config**

| Column | Type | Constraints |
|---|---|---|
| id | TEXT | PK |
| name | TEXT | |
| startDeltaWatts | REAL | |
| startConfirmSeconds | INTEGER | DEFAULT 2 |
| startDropoutTolerance | INTEGER | DEFAULT 1 |
| endDeltaWatts | REAL | |
| endConfirmSeconds | INTEGER | DEFAULT 5 |
| minEffortSeconds | INTEGER | DEFAULT 3 |
| preEffortBaselineWindow | INTEGER | DEFAULT 15 |
| inEffortTrailingWindow | INTEGER | DEFAULT 10 |
| isDefault | BOOLEAN | |

**devices**

| Column | Type | Constraints |
|---|---|---|
| deviceId | TEXT | PK |
| displayName | TEXT | |
| supportedServices | TEXT | JSON list |
| lastConnected | DATETIME | |
| autoConnect | BOOLEAN | DEFAULT TRUE |

**app_settings**

| Column | Type | Constraints |
|---|---|---|
| key | TEXT | PK |
| value | TEXT | |

Used for simple app-level configuration. Known keys in v1: `maxPower` (double as string, nullable — if absent, derived from all-time best 1s power), `theme` ('dark', 'light', 'system').

### 5.3 Indexes
- rides: startTime DESC
- readings: (rideId, offsetSeconds) composite
- efforts: rideId
- map_curves: effortId
- ride_tags: (rideId, tag) composite PK; also INDEX on tag for distinct-tag query

### 5.4 Migration Strategy
- Incremental migrations via Drift's versioned schema system
- Never delete columns — only add nullable columns
- Schema dump at each version for migration testing
- Tests verify migration paths from every previous version

### 5.5 Storage Estimates
- 1-hour ride at 1Hz ≈ 3,600 readings ≈ 700 KB
- MAP cache per effort: 90 rows ≈ 2 KB
- 100 rides of ~1.5h each ≈ 100 MB total
- Batch insert (single transaction) for ride save: < 1 second

---

## 6. Auto-Lap Detection

### 6.1 Approach
Pure delta-based detection using two independent baselines. No absolute thresholds — the system adapts to any riding intensity.

### 6.2 Baselines

**Pre-effort baseline:** Rolling average of power during idle/recovery. Starts at 0 on cold start (a sprint from standstill at 500W produces a +500W delta from baseline 0, which naturally triggers detection). Frozen when an effort triggers. Cleared and reset when an effort ends.

**In-effort trailing average:** Rolling average of power during the effort. Used only for end detection. Adapts to actual effort intensity — a sprint that decays from 700W to 500W uses the trailing average (~500W range) as the end reference. Frozen during pendingEnd.

### 6.3 State Machine

- **Idle → PendingStart:** Triggers when power > preEffortBaseline + startDelta. Tentative start offset recorded (used for backdating).
- **PendingStart → InEffort:** Sustained for startConfirmSeconds with at most startDropoutTolerance readings below threshold. Effort start backdated to tentative start.
- **PendingStart → Idle:** More than startDropoutTolerance dropouts. Baseline unfreezes.
- **InEffort → PendingEnd:** Triggers when power < inEffortTrailing - endDelta. Tentative end offset recorded.
- **PendingEnd → InEffort:** Power rises back above trailing - endDelta (mid-effort dip, not a real end).
- **PendingEnd → EffortComplete → Idle:** Sustained for endConfirmSeconds. Effort validated against minEffortSeconds — if too short, discarded. Effort end trimmed to tentative end point. Baseline unfreezes and clears.

### 6.4 Edge Cases

| Scenario | Behavior |
|---|---|
| Ride ends during InEffort | Finalize effort at last reading, skip min duration check |
| Ride ends during PendingStart | Discard tentative effort |
| Ride ends during PendingEnd | Finalize at tentative end point |
| Manual lap during Idle | Force start, freeze baseline, skip confirmation |
| Manual lap during InEffort | End current + start new effort immediately |
| Manual lap during PendingStart | Confirm immediately → InEffort |
| Manual lap during PendingEnd | Confirm end immediately → Idle |
| Sensor dropout (null readings) | Ignored entirely — nulls don't trigger state changes |
| Cold start (no baseline data) | Baseline = 0, delta triggers naturally |

### 6.5 Configuration Presets

**Short Sprint (< 15s):**
- startDelta: +200W, startConfirm: 1s, 1 dropout tolerance
- endDelta: -150W, endConfirm: 4s
- minEffort: 2s, preEffortWindow: 10s, inEffortWindow: 5s

**Flying 200m (~12s):**
- startDelta: +150W, startConfirm: 2s, 1 dropout tolerance
- endDelta: -120W, endConfirm: 5s
- minEffort: 5s, preEffortWindow: 15s, inEffortWindow: 8s

**Team Sprint (longer efforts):**
- startDelta: +120W, startConfirm: 3s, 1 dropout tolerance
- endDelta: -100W, endConfirm: 6s
- minEffort: 10s, preEffortWindow: 20s, inEffortWindow: 15s

### 6.6 Effort Events
- **EffortStartedEvent:** startOffset, isManual, preEffortBaseline
- **EffortEndedEvent:** startOffset, endOffset, isManual, wasTooShort, preEffortBaseline, peakTrailingAvg

### 6.7 Re-detection
- Efforts can be recomputed from raw readings using a different AutoLapConfig (which may differ from the ride's original config)
- Used for imported rides (source laps are always discarded) and for locally recorded rides if settings were wrong
- The autoLapConfigId on the ride is updated to reflect the config used for the latest detection
- Re-detection shows a preview comparing old vs new efforts before committing
- The re-detection screen offers a "Make default" option to set the previewed config as the app-wide default

---

## 7. MAP Curve Computation

### 7.1 Algorithm
Uses prefix sums for O(1) per-window average calculation. The same algorithm is used for both per-effort MAP curves (input: readings sliced to effort boundaries) and ride-level PDC (input: all effort curves, take max at each duration). The difference is only in the input data, not the computation.

```
prefixSum[0] = 0
prefixSum[i] = prefixSum[i-1] + reading[i-1]
For each duration d (1..90):
  For each window ending at position n:
    avg = (prefixSum[n] - prefixSum[n-d]) / d
    bestAvg[d-1] = max(bestAvg[d-1], avg)
```

### 7.2 Live Computation Optimization
During a ride, only windows ending at the latest reading need to be checked (all earlier windows were evaluated on prior ticks). Each 1Hz update is O(90). Live computation is only used for per-effort MAP curves during an active effort.

### 7.3 Monotonicity Enforcement
After computing raw best averages, sweep right-to-left:

```
for i from 88 down to 0:
  if bestAvg[i] < bestAvg[i+1]:
    bestAvg[i] = bestAvg[i+1]
    flags[i].wasEnforced = true
```

Applied to: live effort curves, cached effort curves, derived ride-level PDC, historical best and worst envelopes.

### 7.4 Null Handling
Null power readings (sensor dropout) contribute 0W to window sums. A window containing nulls uses the full window size `d` as the denominator, so dropout seconds reduce the average proportionally. A window of all nulls produces 0. This prevents inflation of longer-duration values when nulls cluster near high-power readings.

When computing the best window for each duration, track whether the winning window contained any nulls:

```
for each duration d (1..90):
  for each window ending at position n:
    nonNullCount = countSum[n] - countSum[n-d]
    if nonNullCount == 0: avg = 0
    else: avg = (powerSum[n] - powerSum[n-d]) / d
    if avg > bestAvg[d-1]:
      bestAvg[d-1] = avg
      flags[d-1].hadNulls = (nonNullCount < d)
```

### 7.5 Caching
Per-effort MAP curves are computed when an effort ends (or ride ends) and cached in the map_curves table (90 rows per effort). Ride-level PDC is computed on demand by taking the max at each duration across all effort MapCurves for that ride — no separate table needed. For historical queries (all-time PDC, best/worst envelopes), cached effort curves are loaded directly — no need to reload raw readings. A recompute can be triggered manually or after data correction.

---

## 8. TCX Import/Export

### 8.1 Export
Mapping:
- Ride → Activity (Sport="Biking")
- Ride.startTime → Activity/Id (ISO 8601)
- Efforts → Laps with Intensity="Active", recovery gaps → Laps with Intensity="Resting"
- SensorReading → Trackpoint (Time, HeartRateBpm/Value, Cadence)
- SensorReading.power → Extensions/TPX/Watts (Garmin Activity Extension v2 namespace)
- Null fields → element omitted from Trackpoint
- Exported in v1: power, heartRate, cadence, crankTorque, accumulatedTorque, crankRevolutions, lastCrankEventTime, maxForceMagnitude, minForceMagnitude, maxTorqueMagnitude, minTorqueMagnitude, topDeadSpotAngle, bottomDeadSpotAngle, accumulatedEnergy, rrIntervals. All raw sensor fields are included so external tools can process the full data.
- Not exported in v1: leftRightBalance, leftPower, rightPower (no standard TCX mapping)
- Validation before export: clamp out-of-range values, fill timestamp gaps, convert offsets to absolute timestamps using ride startTime + timezone

### 8.2 Import
All source laps are discarded. Trackpoints are flattened into a continuous ordered stream regardless of the source file's lap structure.

Flow: Parse XML → flatten trackpoints → build Ride with Readings → run AutoLapDetector (same algorithm as live) → generate Efforts → compute MapCurves and Summaries → return Ride (caller handles persistence).

- Power 0 vs null distinction: TCX `<Watts>0</Watts>` = rider coasting (include in MAP calc as zero). Missing Watts element = sensor dropout (null, skip in MAP calc).
- Namespace handling: Detect Garmin Activity Extension namespace regardless of prefix (ns3:, tpx:, etc.).
- Bulk import: ZIP archives containing multiple TCX files. Iterate, import each independently, log failures, show summary.

### 8.3 Garmin Activity Extension Namespace

```xml
xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2"

<!-- Power per trackpoint: -->
<Extensions>
  <ns3:TPX>
    <ns3:Watts>350</ns3:Watts>
  </ns3:TPX>
</Extensions>
```

---

## 9. UI / Screen Flow

### 9.1 Navigation Pattern
Responsive — the Ride Screen is the home screen. On compact layouts, other screens are accessed via a menu or bottom navigation. On medium/expanded layouts, a navigation rail on the left provides access to all screens. Device connection is accessible from the sensor status icon on any screen (or by pressing D).

### 9.2 Theme
Dark by default. User can switch to light or system-follow in settings.

### 9.3 Layout & Orientation

The app uses a responsive layout that adapts to available width, covering both mobile orientations and desktop window sizes.

| Layout | Width | Behavior |
|--------|-------|----------|
| **Compact** | < 600dp | Mobile portrait behavior: Focus or Chart mode (toggle via swipe, keyboard, or segmented control). Landscape on mobile always shows Chart. |
| **Medium** | 600–899dp | Navigation rail on left, single content panel. Focus/Chart toggle still applies. |
| **Expanded** | ≥ 900dp | Navigation rail on left, Focus + Chart panels shown side-by-side during active ride (no toggle needed). |

- Orientation is auto-detected on mobile; desktop uses window width for layout decisions
- Smooth animated transitions between layout sizes
- Minimum window size on desktop: 400×600

### 9.4 Screens

#### 9.4.1 Ride Screen (Primary/Home)

Three ride states × multiple layout variants = several layouts. On compact/medium: focus or chart mode with toggle. On expanded: focus + chart side-by-side.

**Idle (no active ride):**
- Portrait: ambient PDC / last ride summary card (date/time, tags, key stats), large Start Ride button, sensor status icon
- Start Ride with no sensor connected → opens device connection sheet

**Active ride — Focus Mode (portrait):**

During effort:
- Current power: ~100pt, fills screen
- Effort duration counting up
- Background tints by % of maxPower (from maxPowerProvider: manual override or all-time best 1s): blue (< 30%) → purple (30–60%) → yellow (60–80%) → orange (80–95%) → red + pulse (> 95%)
- HR and cadence in corners (small)
- Manual lap and stop buttons at bottom

Between efforts:
- Last effort summary: effort number, duration, avg power, peak power
- Key MAP durations (1s, 5s, 10s, 30s) for that effort
- Recovery timer counting up
- Current baseline indicator

**Active ride — Chart Mode (portrait):**

During effort:
- Live MAP curve building in real time (bold gradient line: red → yellow → blue)
- Previous session efforts as faded lines behind
- Historical best/worst envelope as shaded band (upper bound = PDC for selected span)
- Record-breaking points highlighted (glow + haptic)
- Key duration stats updating live at bottom
- Current power, HR, cadence at top

Between efforts:
- Last completed effort's curve shown solid
- Previous efforts faded behind
- Historical band visible
- "Waiting for effort…" indicator

**Active ride — Landscape / medium layout (always chart):**
- Chart fills ~85% of screen width
- Left panel: power, HR, cadence, effort info, lap/stop buttons
- Key duration stats overlaid at chart bottom edge

**Active ride — Expanded layout (≥ 900dp):**
- Focus panel (~40% width) + Chart panel (~60% width) side by side
- Both panels update in real time during effort
- LAP/STOP buttons in focus panel
- No mode toggle needed — both modes always visible
- Key duration stats at chart bottom edge

**Interaction details:**
- Focus ↔ Chart toggle (compact/medium only): horizontal swipe (touch, minimum 80px) OR left/right arrow keys (keyboard) OR segmented control pills (click/tap). No tap-to-toggle on empty areas — taps reserved for buttons and interactive elements.
- On expanded layout, both modes are always visible — no toggle needed
- Landscape triggered by device rotation (mobile) or window width (desktop)
- Start ride: tap Start button OR press Enter (when sensor connected)
- Stop ride: long-press 1.5s (touch) with circular progress indicator, OR press Escape → confirmation dialog (keyboard)
- Manual lap: tap LAP button (48×48 minimum touch target) OR press Space
- Open device connection: tap sensor status bar OR press D
- Screen stays awake during active ride (wakelock on supported platforms)

#### 9.4.2 Device Connection
- On compact layout: modal bottom sheet. On medium/expanded: centered dialog (max 480px wide).
- Remembered devices at top with status and connect/disconnect toggle
- Scan results below with signal strength and service icons (power/HR/cadence)
- Tap/click discovered device to connect and remember
- Dismiss by swipe-down (mobile) or close button/Escape (desktop) — connection persists in background

#### 9.4.3 Ride History
- Scrollable list, most recent first
- Each card: date/time (local format), tags, duration, effort count, avg power, power trace sparkline
- Filters: time span selector (week/month/year/all) and tag filter (most frequent tags shown as tappable chips, consistent with Ride Detail tag input)
- Tap → Ride Detail
- Swipe to delete (touch) or select + Delete key (keyboard), both with confirmation
- Import rides button at bottom

#### 9.4.4 Ride Detail
- Ride date/time and tags at top (tags are editable: top 2–5 most frequent tags shown as tappable chips for quick add, with a text field for free-form entry that filters remaining tags as the user types)
- Ride summary stats
- Effort timeline: horizontal bar with colored effort segments (intensity-coded by avg power)
- Effort cards: expandable list with per-effort stats and MAP curve thumbnail
- Expanded card: full MAP curve with historical band, per-second power trace
- Actions: Export (TCX), Re-detect efforts, Delete ride

#### 9.4.5 Power Duration Curve
- Full chart with best envelope as primary bold line (from historicalRangeProvider)
- Independent time span selector (drives spanSelectionProvider)
- Tag filter (same as History, drives tagFilterProvider)
- Tappable points → tooltip with power value, source effort, ride date (from provenance)
- Key duration stat cards at bottom
- Landscape / expanded layout: chart fills available space

#### 9.4.6 Settings
- Auto-lap configuration (→ config screen with presets and manual parameter entry)
- Max power: displays current value (auto-derived from all-time best 1s, or manual override). Used for Focus Mode background color scaling (% of record). Toggle between "Auto" and manual entry.
- Import rides (file picker, progress, results)
- Devices (manage remembered devices)
- Appearance (dark/light/system)

#### 9.4.7 Auto-Lap Config Screen
- Preset selector: Short Sprint / Flying 200 / Team Sprint / Custom
- Parameter fields with numeric input and tooltips explaining each parameter
- Selecting a preset fills all fields; modifying any field switches to "Custom"
- Save button applies config as new default

### 9.5 Keyboard Shortcuts

Keyboard shortcuts are available on all platforms but primarily useful on desktop (physical keyboard). On mobile without a physical keyboard, the `Shortcuts` widget is inert — no platform check needed.

| Key | Action | Context |
|-----|--------|---------|
| ← Left arrow | Switch to Focus mode | Active ride, compact/medium layout |
| → Right arrow | Switch to Chart mode | Active ride, compact/medium layout |
| Space | Manual LAP | Active ride |
| Escape | Stop ride (shows confirmation dialog) | Active ride |
| Enter | Start ride | Idle, sensor connected |
| D | Open device connection sheet/dialog | Any |

### 9.6 Desktop Interaction Polish

- **Mouse cursors**: Clickable elements show pointer cursor on hover
- **Tooltips**: Interactive elements show tooltip with action name and keyboard shortcut (e.g., "Manual lap (Space)")
- **Hover states**: Buttons and interactive elements show hover highlight
- **Scrollbars**: Visible by default on desktop (Flutter platform default)

---

## 10. Testing Strategy

### 10.1 Domain Layer — Unit Tests (highest priority, pure Dart)

**MapCurveCalculator:**
- Known power sequences with hand-calculated expected results
- Monotonicity enforcement on naturally non-monotonic data
- All-null readings → all zeros
- Single reading → propagated to all durations
- Incremental (live) vs batch (post-ride) equivalence
- Property-based: random sequences always produce non-increasing output where 1s best = max reading
- hadNulls and wasEnforced flags set correctly

**AutoLapDetector:**
- Clean sprint (clear start/stop)
- Noisy sprint (mid-effort dips within dropout tolerance)
- Too-short spike (discarded by minEffortSeconds)
- Back-to-back with insufficient recovery (merged into one effort)
- Back-to-back with adequate recovery (two separate efforts)
- Cold start sprint (baseline = 0)
- Gradual ramp (no false trigger)
- Sensor dropout mid-effort (nulls ignored)
- Ride end in each state
- Manual lap in each state
- Baseline freeze/unfreeze verification
- Trailing average tracks effort decay
- Recovery baseline reset after effort

**RollingBaseline:**
- Buffer filling and windowed average
- Freeze/unfreeze/clear
- Empty buffer returns 0
- Window size respected

**HistoricalRangeCalculator:**
- Best/worst envelopes with provenance from multiple efforts (single pass)
- Monotonicity on both envelopes
- Provenance inherited correctly when monotonicity enforcement bumps a value
- Date filtering
- Tag filtering
- Single effort: best = worst, same provenance
- Best values serve as PDC for same span

**SummaryCalculator:**
- All-null readings (no NaN)
- Mixed null/value averaging
- Kilojoules computation
- L/R balance averaging (only from readings where present)
- RideSummary avgPower computed from active effort readings only (recovery excluded)
- RideSummary with zero efforts (activeDurationSeconds = 0, avgPower = 0)

### 10.2 Data Layer — Integration Tests (Flutter)

**BLE Profile Parsers:**
- Power: all flag combinations, endianness, L/R balance extraction
- HR: 8-bit vs 16-bit, with/without RR intervals
- CSC: cadence from deltas, counter rollover, first reading → null

**Database (Drift in-memory):**
- Ride CRUD round-trip (all fields including tags)
- Tag storage, retrieval, and distinct-tag query
- Reading batch insert (7200 rows in transaction)
- Effort + MapCurve cascade on delete
- Historical query with date and tag filter
- Migration paths from every previous version

**TCX Serializer/Parser:**
- Round-trip fidelity (export → import → compare)
- Null → omit → null preserved
- All raw sensor fields exported correctly
- Namespace detection variants
- Real files from Garmin, Wahoo, Strava
- Malformed XML recovery (skip bad trackpoints)
- Source laps correctly ignored on import

### 10.3 Presentation Layer — Widget + Provider Tests

**Widget tests:**
- Ride screen in each state: correct buttons/elements present
- Focus ↔ Chart mode toggle (swipe, keyboard shortcut, segmented control)
- Device sheet/dialog: scan results display
- Layout transitions (compact ↔ medium ↔ expanded)
- Keyboard shortcut intents fire correct actions
- Tag input with suggestions

**Provider tests:**
- Sensor reading → session → effort flow with mocked BLE
- Ride list filtering by span and tags
- Span change → recompute historical range and re-filter ride list
- PDC screen uses historicalRangeProvider best envelope (with provenance for drill-down)

### 10.4 Manual Testing

**BLE on real hardware (per platform):**
- Actual sensors (power meter, HR strap)
- Connection reliability and reconnection
- Data accuracy vs reference device
- Desktop BLE: macOS (native CoreBluetooth), Windows (WinRT), Linux (BlueZ)

**Visual/UX:**
- Chart rendering correctness
- Layout transitions (orientation on mobile, window resize on desktop)
- Focus mode readability at arm's length
- Record-breaking animation
- Sunlight readability

**Performance:**
- 1Hz update smoothness
- Long ride memory usage
- History screen with 500+ rides
- Bulk import speed

### 10.5 CI Pipeline
- dart test (domain): < 5 seconds
- flutter test (data layer): < 15 seconds
- flutter test (widgets/providers): < 30 seconds
- Total: < 1 minute, runs on every commit

---

## 11. Future Considerations (out of scope for v1)

**v1.1 — Near-term (OAuth-dependent features):**
- Strava integration — OAuth2 connection to upload rides (TCX) and pull activities via Strava V3 API (free, no registration cost). Requires flutter_secure_storage for token management and deep link setup on mobile platforms.
- Cloud backup — Sync/backup local SQLite DB to cloud storage (GDrive, iCloud, Dropbox). Local DB remains source of truth. Also OAuth-dependent. Can share OAuth infrastructure with Strava integration.

**Later:**
- FIT file support — binary format, more complex parsing, add as additional serializer
- FTP and power zones — endurance-focused metrics, not relevant for sprint training
- Multiple simultaneous BLE devices — separate HR strap + power meter, requires stream merging
- Laps by distance/location — GPS integration
- Pedal stroke analysis — force/angle polar chart from extreme angle data (raw data already stored)
- HRV analysis — from stored RR-intervals (raw data already stored)
- Rider weight and W/kg display — add RiderProfile model, per-screen display rules
- Apple Watch / Wear OS companion — display focus-mode data on wrist

**Gearing detection per effort**

Each effort records the gear used during that effort, expressed as chainring × sprocket (e.g. 52×15). Gearing is auto-detected when speed and cadence data are both available — either from sensors during recording or from speed/cadence fields in an imported TCX file. If either is unavailable, or if the speed source is virtual (see below), the gearing field is silently omitted (nullable).

*Detection algorithm:*

- Wheel speed (m/s) is converted to wheel RPM using a hardcoded standard track wheel circumference (700c × 23mm ≈ 2096mm). Wheel size will be user-configurable in a later version.
- Gear ratio = wheel RPM / crank RPM.
- The ratio is matched against the closest valid combination from a generated lookup table of all chainring × sprocket combinations in the range 46–60t chainrings × 12–17t sprockets (90 combinations total). The table is generated programmatically at runtime from the tooth count ranges, which are the single source of truth. It lives in `core/` as a lazy singleton and is unit tested to verify known combinations and ratio correctness.
- A computed ratio is only matched if it falls within 1% of a valid combination. Ratios outside this threshold produce a null result.
- When two combinations are equidistant (within the 1% threshold), the combination with the smaller chainring is preferred.
- Only readings where cadence ≥ 60 RPM contribute to the modal calculation, excluding the initial acceleration phase where the ratio is noisy and unreliable. This threshold may need tuning based on real-world testing.
- The modal gear across all qualifying readings within the effort is the representative gear for that effort.

*Data source priority:*

- Same-source pairing takes precedence: if a CSC sensor provides both speed and cadence, that pairing is used. If the power meter provides both crank revolution data and no CSC is present, that pairing is used.
- Cross-source pairing (CSC speed + power meter cadence, or vice versa) is the fallback when same-source data is unavailable.
- Virtual speed sources (see below) suppress gear detection regardless of cadence availability.

*Virtual speed (ergs and indoor trainers):*

Bike ergometers such as Wattbike, and smart trainers such as Tacx and Wahoo Kickr, report a virtual speed derived from power output rather than actual wheel rotation. This speed is not usable for gear ratio calculation and must be suppressed.

- Each remembered device has a **virtual speed** flag (persisted in the `devices` table as `virtualSpeed: bool`).
- The flag is auto-enabled when the device name or manufacturer matches a known erg/trainer list maintained in `core/` (initially: Wattbike, Tacx, Wahoo, Kickr).
- The user can override the flag in either direction in device settings — force-enable for an unrecognised erg, or force-disable if a known erg name matches a real wheel-based device.
- For TCX imports, the `<Creator>` field is checked against the same known erg/trainer list. If matched, gear detection is suppressed for that import.
- The `DeviceInfo` model gains a `virtualSpeed: bool` field (default false, auto-set on first connection for known devices).

*Live gear display during rest:*

Gear detection runs continuously during the rest phase between efforts, not only within effort boundaries. The currently detected gear is displayed in real time on the Ride screen's between-effort state, alongside the recovery timer and last effort summary. This gives the rider a natural opportunity to roll and verify the detected gear is correct before the next effort. The display updates on each 1Hz tick using the same algorithm as per-effort detection (cadence ≥ 60 RPM filter still applies).

*UI placement:*

- **Ride screen, rest state** — live detected gear, updates in real time
- **Ride Detail effort cards** — stored modal gear for each effort (nullable, omitted if not detected)
- **PDC provenance tooltip** — gear shown when drilling down from a PDC point to its source effort

*Data model:*

`EffortSummary` gains two nullable integer fields: `chainring: int?` and `sprocket: int?`. These are stored as separate columns in the `efforts` table rather than a combined ratio, preserving the full chainring × sprocket identity.

*Gear-based filtering and grouping in History is explicitly out of scope for this version and noted as a further future extension.*

**TCX "Share to" / file association (mobile)**

On iOS and Android, the app should register as a handler for TCX files so that riders can import directly from other apps or browsers without navigating to the in-app file picker. Examples: opening a downloaded TCX from Safari/Chrome, or sharing from Garmin Connect or Strava's mobile app.

Implementation requires:
- **iOS** — declare a document type and UTI (`com.garmin.tcx` or a custom UTI with `.tcx` extension) in `Info.plist`, and handle the incoming file via the `AppDelegate` / Flutter method channel
- **Android** — declare an intent filter for `ACTION_VIEW` and `ACTION_SEND` with MIME type `application/vnd.garmin.tcx+xml` (and `application/octet-stream` as fallback) in `AndroidManifest.xml`
- Both platforms feed the received file path/URI into the existing `TcxParser` import flow — no parser changes needed
- Desktop platforms (macOS, Windows, Linux) have analogous file association mechanisms and should be handled at the same time

### Phase Detection and Trend Analysis

**Background**

Single-session personal bests — already tracked by Wattalizer’s `HistoricalRange.best` envelope — tell you the ceiling of what an athlete has achieved, but they do not describe the athlete’s *current typical state*. Performance fluctuates from session to session for reasons unrelated to genuine adaptation (fatigue, sleep, motivation, track conditions). A new all-time best in one session may be a genuine upward shift, or it may be an anomaly that will not be reproduced for months. Conversely, an athlete can remain well below their PB for an extended stretch while their typical performance level has meaningfully improved.

The goal of this feature set is to distinguish between normal session-to-session fluctuation and genuine shifts in the underlying level around which performance fluctuates. All three layers build on top of existing `MapCurve` cache data and require no changes to the BLE pipeline, recording flow, or core data models.

The input series for all calculations below is the **per-session best** at a given duration `d`: for each ride, take `max(effort.mapCurve.values[d-1])` across all efforts in that ride. This is already computable from cached `map_curves` rows without reloading raw readings. The series is ordered by `ride.startTime` ascending and indexed as `p[0], p[1], … p[N-1]` where `N` is the number of sessions in the selected span/tag filter.

-----

#### Layer 1 — Exponential Moving Average (EMA)

**Purpose:** Produce a smoothed estimate of the athlete’s current typical performance level at each duration, responsive to recent sessions while dampening noise from single outlier efforts.

**Calculation:**

```
EMA[0] = p[0]
EMA[i] = α × p[i] + (1 − α) × EMA[i-1]   for i = 1..N-1
```

where `α` is the smoothing factor, `0 < α ≤ 1`. Higher `α` = more weight on recent sessions, lower `α` = more historical smoothing. Default `α = 0.3` (approximately equivalent to a 6-session half-life). Expose as a user-configurable setting with sensible labels (e.g., “Responsive / Balanced / Stable” mapping to α = 0.5 / 0.3 / 0.15).

**Bootstrapping:** The first EMA value is the first session’s per-session best. The EMA becomes meaningful after approximately `1/α` sessions (i.e., ~3 sessions at α = 0.3 is the minimum before displaying). Below this threshold, display nothing rather than a misleading early value.

**Monotonicity:** EMA is computed independently per duration `d`. There is no constraint that the resulting EMA curve at any point in time must be non-increasing across durations — unlike `MapCurve.values`, EMA values represent smoothed typical performance at individual durations, not a coherent power-duration curve snapshot. If a monotonically-consistent EMA curve is needed for display (e.g., as an overlay on the PDC chart), apply the same right-to-left monotonicity sweep used by `MapCurveCalculator` across the 90 EMA values at the latest session index.

**Storage:** EMA values are not persisted. They are computed on demand in a new `TrendCalculator` domain class from the ordered series of per-session bests. The `historicalEmaProvider` (new) depends on `historicalRangeProvider` and `emaConfigProvider` (new, stores α). Recomputation is triggered whenever span, tag filter, or α changes.

-----

#### Layer 2 — CUSUM Phase Detection

**Purpose:** Formally detect when the athlete’s typical performance level has shifted to a new phase — i.e., when a sustained deviation from the current reference mean has accumulated beyond a decision threshold. Output is a list of **phase boundaries** (session indices at which a shift was detected) and the **baseline mean** for each resulting phase.

**Inputs (per duration `d`):**

- `p[0..N-1]` — per-session best series (same as EMA input)
- `μ` — reference mean for the current phase (initialized to the mean of the first `w` sessions, default `w = 5`)
- `k` — slack parameter controlling sensitivity; filters out fluctuations smaller than `k` watts before accumulating. Recommended default: `k = σ / 2` where `σ` is the standard deviation of the first `w` sessions. Expose as a user-configurable sensitivity slider (Low / Medium / High mapping to `k = σ`, `k = σ/2`, `k = σ/4`).
- `h` — decision threshold; the cumulative sum must exceed `h` before a phase shift is signaled. Recommended default: `h = 5σ`. Same sensitivity slider as `k`.

**Running CUSUM (two-sided):**

```
S_pos[0] = 0
S_neg[0] = 0

For i = 1..N-1:
  S_pos[i] = max(0, S_pos[i-1] + (p[i] − μ − k))
  S_neg[i] = min(0, S_neg[i-1] + (p[i] − μ + k))

  if S_pos[i] > h:
    → upward phase shift detected at session i
    → record PhasePoint(sessionIndex: i, direction: up, newMean: mean of recent w sessions ending at i)
    → reset: S_pos[i] = 0, S_neg[i] = 0
    → update μ to newMean

  if S_neg[i] < −h:
    → downward phase shift detected at session i
    → record PhasePoint(sessionIndex: i, direction: down, newMean: mean of recent w sessions ending at i)
    → reset: S_pos[i] = 0, S_neg[i] = 0
    → update μ to newMean
```

**Phase mean calculation:** When a shift is detected at session `i`, the new phase mean `μ_new` is the arithmetic mean of `p[max(0, i−w+1)..i]` (the most recent `w` sessions). This avoids being anchored to the old phase’s data. If fewer than `w` sessions are available since the last shift, use all available sessions since that shift.

**Output — `PhaseDetectionResult`:**

```dart
class PhasePoint {
  final int sessionIndex;    // index into the ordered session series
  final String rideId;       // for UI drill-down
  final DateTime rideDate;
  final PhaseDirection direction;  // up | down
  final double previousMean; // μ before this shift (watts)
  final double newMean;      // μ after this shift (watts)
}

class PhaseDetectionResult {
  final int durationSeconds;         // 1–90
  final List<PhasePoint> shifts;     // ordered by sessionIndex
  final List<PhaseMeanSegment> segments; // contiguous phase segments with their mean
  final double currentPhaseMean;     // mean of the current (last) phase
}

class PhaseMeanSegment {
  final int startSessionIndex;
  final int endSessionIndex;         // inclusive; last segment's end = N-1
  final double mean;
  final double stdDev;
}
```

**Key durations:** CUSUM is computed for all 90 durations, but the UI surfaces results primarily at the four key durations already used in the app: 1s, 5s, 10s, 30s. Full 90-duration results are available for drill-down.

**Minimum data requirement:** At least `2w` sessions (i.e., 10 sessions at default `w = 5`) before displaying any CUSUM results. Below this, the feature is hidden rather than showing potentially misleading signals.

**Storage:** Phase detection results are not persisted. They are computed on demand by a new `PhaseDetector` domain class. A new `phaseDetectionProvider` (new) depends on `historicalRangeProvider` and `cusumConfigProvider` (new, stores `k`, `h`, `w`). Like EMA, recomputation is triggered on span, tag filter, or config changes.

-----

#### Layer 3 — Variation Monitoring

**Purpose:** Detect when within-session variability across efforts is narrowing over time — a signal of potential rigidity, where the training stimulus is no longer sufficiently varied to stress the system. This complements phase level detection (Layers 1–2) with phase *variability* detection.

**Input series (per duration `d`):** For each session `i`, compute `σ_session[i]` = the standard deviation of `effort.mapCurve.values[d-1]` across all efforts in that session. Sessions with fewer than 3 efforts produce a null entry and are excluded from the series.

**Rolling variability mean:**

```
V[i] = mean(σ_session[max(0, i−w+1) .. i])   where w = 5 (default)
```

`V[i]` is the rolling average of within-session spread over the recent `w` sessions. A sustained downward trend in `V` — i.e., V[i] < V[i−w] for several consecutive windows — is the signal of narrowing variability.

**Formal detection (optional, configurable):** Apply the same CUSUM machinery from Layer 2 to the `V` series rather than `p` to formally detect when variability has shifted to a lower phase. In practice, a simple threshold check suffices: flag a “low variability” warning when `V[i] < 0.1 × currentPhaseMean` (i.e., within-session spread is less than 10% of the current typical power level at that duration).

**Output:** A boolean `lowVariabilityWarning` flag per duration, plus the current `V[i]` value. Surfaced only as a subtle UI indicator — not as a primary metric.

-----

#### Data Model Additions

No new database tables are required. All computed values are derived on demand from existing `map_curves` rows. The following new domain classes are added to the domain layer:

```dart
// lib/domain/trend/
TrendCalculator      // computes EMA series from per-session best series
PhaseDetector        // computes CUSUM phase detection result
VariationMonitor     // computes rolling variability and low-variability flag
```

New providers in the presentation layer:

```dart
historicalEmaProvider          // depends on: historicalRangeProvider, emaConfigProvider
phaseDetectionProvider         // depends on: historicalRangeProvider, cusumConfigProvider
variationMonitorProvider       // depends on: historicalRangeProvider, cusumConfigProvider
emaConfigProvider              // α value (user setting, persisted in app_settings)
cusumConfigProvider            // k, h, w values (user setting, persisted in app_settings)
showPhaseShiftMarkersProvider  // boolean (user setting, persisted in app_settings)
```

New `app_settings` keys: `emaAlpha` (double), `cusumSensitivity` (string: ‘low’ | ‘medium’ | ‘high’), `cusumWindowSize` (int), `showPhaseShiftMarkers` (bool, default true).

-----

#### UI Integration

**PDC Screen additions:**

- EMA overlay: a secondary line on the PDC chart rendered behind the best-envelope bold line. Distinct style (dashed or lower-opacity, same hue family as the best envelope line). Labeled “Typical level.” Always rendered when ≥ `1/α` sessions are available — no on-screen toggle.
- Phase mean segments: horizontal shaded bands spanning the x-axis (date) range for each `PhaseMeanSegment`, rendered at the y-axis level corresponding to that segment’s mean at the selected duration. Always rendered when ≥ `2w` sessions are available — no on-screen toggle. Tapping a phase band shows a tooltip: mean watts, session count, date range.
- Phase shift markers: vertical lines at the x-axis position of each `PhasePoint`, colored green (upward shift) or amber (downward shift). Tapping shows the `PhasePoint` detail: direction, magnitude of shift (newMean − previousMean in watts and %). Visibility controlled by the `showPhaseShiftMarkersProvider` setting — no on-screen toggle on the PDC screen itself.

**Settings screen additions (new “Trend Analysis” section):**

- EMA smoothing: segmented control labeled “Responsive / Balanced / Stable” mapping to α = 0.5 / 0.3 / 0.15. Default: Balanced.
- CUSUM sensitivity: segmented control labeled “Low / Medium / High” mapping to `k = σ`, `σ/2`, `σ/4` and `h = 3σ`, `5σ`, `8σ`. Default: Medium.
- Show phase shift markers: toggle switch. Default: on. Controls `showPhaseShiftMarkersProvider`. When off, EMA and phase bands still render; only the vertical shift marker lines are suppressed.

**History screen additions:**

- Phase shift markers on the session list: a subtle icon on the ride card for rides that are identified as a phase boundary (from the 5s duration CUSUM result, as a representative key duration).
- Low variability warning: a subtle icon on the ride card when `lowVariabilityWarning` is true for the 5s duration.

**Key duration stat cards (existing, on PDC screen):**

- Add EMA value below the all-time best value. Label: “Typical.” Only shown when ≥ `1/α` sessions exist.
- Add phase shift delta below EMA when the current phase differs from the previous: “+12W since [date]” or “−8W since [date].”

-----

#### Testing

**Domain unit tests — `TrendCalculator`:**

- Known series with hand-computed EMA at α = 0.3 and α = 0.5
- First value equals `p[0]`
- Series of identical values → EMA remains constant
- Single large spike does not permanently shift EMA
- Monotonicity sweep on 90-duration EMA snapshot

**Domain unit tests — `PhaseDetector`:**

- Flat series → no shifts detected
- Series with clear step change (e.g., +100W from session 10 onward) → single upward shift detected at or near session 10 + confirmation lag
- Downward step change → downward shift detected
- Two sequential shifts (up then down) → two phase points, correct means
- Series shorter than `2w` → empty result, no crash
- `k = 0` with flat series → no spurious signals (S resets to 0 on every session)
- Correct `rideId` and `rideDate` on `PhasePoint` for drill-down

**Domain unit tests — `VariationMonitor`:**

- Sessions with consistent effort spread → V stable, no warning
- Sessions where all efforts converge to same power → V trends to 0, warning fires
- Sessions with < 3 efforts excluded from V series without crash
- Warning threshold: `V < 0.1 × currentPhaseMean` correctly triggers flag

**Provider tests:**

- Span change → all three providers recompute
- Tag filter change → all three providers recompute
- `emaConfigProvider` α change → `historicalEmaProvider` recomputes
- `cusumConfigProvider` change → `phaseDetectionProvider` and `variationMonitorProvider` recompute
- PDC screen renders EMA overlay only when ≥ `1/α` sessions available
- PDC screen renders phase bands only when ≥ `2w` sessions available
- Phase shift markers hidden when `showPhaseShiftMarkersProvider` is false, visible when true
- Phase shift markers absent regardless of setting when fewer than `2w` sessions available

---

## 12. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.x
  universal_ble: ^1.x     # cross-platform BLE (iOS, Android, macOS, Windows, Linux)
  drift: ^2.x
  sqlite3_flutter_libs: ^0.x
  fl_chart: ^1.x
  path_provider: ^2.x
  share_plus: ^12.x
  file_picker: ^10.x
  xml: ^6.x               # TCX parsing
  uuid: ^4.x
  wakelock_plus: ^1.x     # screen awake (macOS/Windows/iOS/Android; no-op on Linux)
  archive: ^4.x           # ZIP import

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.x
  build_runner: ^2.x
  mockito: ^5.x
  very_good_analysis: ^10.x
```
