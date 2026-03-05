# Wattalizer – Spec Supplement v1.1

## Purpose

This supplement resolves ambiguities and adds explicit contracts to the main specification (v1.2) so that an AI coding agent (e.g., Claude Code) can implement the app without human judgment calls. Every section references the gap it closes.

---

## S1. Core Interface Contracts

### S1.1 BleService (Abstract Interface)

```dart
abstract class BleService {
  /// Scan for nearby BLE devices advertising supported services.
  /// Emits discovered devices continuously until stopScan() is called.
  /// Each emission is a snapshot — devices may appear/disappear.
  Stream<List<DiscoveredDevice>> scanForDevices();
  void stopScan();

  /// Connect to a specific device. Throws BleConnectionException on failure.
  /// Internally manages the full state machine:
  ///   Disconnected → Connecting → DiscoveringServices → Subscribing → Connected
  /// Caller does NOT need to discover services or subscribe manually.
  Future<void> connect(String deviceId);
  Future<void> disconnect(String deviceId);

  /// Connection state stream for a specific device.
  /// Emits: disconnected, connecting, connected, reconnecting
  Stream<BleConnectionState> connectionState(String deviceId);

  /// Merged sensor data stream. Emits RawSensorData which may contain
  /// power, HR, cadence, or any combination depending on device capabilities.
  /// Only emits while connected. Completes on disconnect.
  /// The implementation subscribes to all supported characteristics internally.
  Stream<RawSensorData> sensorStream(String deviceId);

  /// No writes to characteristics in v1.
  /// Power meters that require Control Point activation (0x2A66) are
  /// NOT supported. Document this as a known limitation.
  /// Supported: devices that stream on subscribe (vast majority).
}

enum BleConnectionState { disconnected, connecting, connected, reconnecting }

class DiscoveredDevice {
  final String deviceId;
  final String name;
  final int rssi; // signal strength in dBm
  final Set<SensorType> advertisedServices;
}

class RawSensorData {
  final DateTime receivedAt;
  final PowerData? power;     // from 0x2A63
  final HeartRateData? hr;    // from 0x2A37
  final CadenceData? cadence; // from 0x2A5B
}
```

### S1.2 RideRepository (Abstract Interface)

```dart
abstract class RideRepository {
  // --- Ride CRUD ---
  Future<void> saveRide(Ride ride);
  Future<void> updateRide(Ride ride); // tags, notes only
  Future<Ride?> getRide(String id);
  Future<List<RideSummaryRow>> getRides({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,  // filter by tags (AND logic: ride must have all specified tags)
    int? limit,
    int offset = 0,
  });
  Future<void> deleteRide(String id); // cascades: efforts, readings, map_curves, ride_tags

  // --- Readings ---
  /// Lazy-loaded. Returns readings for offset range [startOffset, endOffset] inclusive.
  Future<List<SensorReading>> getReadings(String rideId, {int? startOffset, int? endOffset});

  /// Batch insert in a single transaction. Used on ride save and TCX import.
  Future<void> insertReadings(String rideId, List<SensorReading> readings);

  // --- Efforts ---
  Future<List<Effort>> getEfforts(String rideId);
  Future<void> saveEfforts(String rideId, List<Effort> efforts); // replaces all efforts for ride
  Future<void> deleteEfforts(String rideId);

  // --- MAP Curves ---
  Future<void> saveMapCurve(String entityId, MapCurve curve);
  Future<MapCurve?> getMapCurve(String entityId);
  Future<List<MapCurve>> getMapCurvesForRide(String rideId);

  /// For historical calculations. Returns all effort-level curves within date range
  /// and matching tag filter. Joins through efforts → rides to filter.
  Future<List<MapCurveWithProvenance>> getAllEffortCurves({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,
  });

  // --- Tags ---
  /// Returns all distinct tags across all rides, sorted alphabetically.
  /// Used for tag input suggestions.
  Future<List<String>> getAllTags();

  // --- Ride-level PDC ---
  /// Best power for each duration (1–90s) across ALL readings in the ride,
  /// regardless of effort boundaries. Useful for "best of session" view.
  Future<void> saveRidePdc(String rideId, MapCurve curve);
  Future<MapCurve?> getRidePdc(String rideId);

  // --- AutoLap Config ---
  Future<List<AutoLapConfig>> getAutoLapConfigs();
  Future<AutoLapConfig> getDefaultConfig();
  Future<void> saveAutoLapConfig(AutoLapConfig config);

  // --- Devices ---
  Future<List<DeviceInfo>> getRememberedDevices();
  Future<void> saveDevice(DeviceInfo device);
  Future<void> deleteDevice(String deviceId);
  Future<List<DeviceInfo>> getAutoConnectDevices();

  // --- Rider Profile --- REMOVED (weight/W per kg dropped from v1)
}

class MapCurveWithProvenance {
  final String effortId;
  final String rideId;
  final DateTime rideDate;
  final int effortNumber;
  final MapCurve curve;
}

class RideSummaryRow {
  final String id;
  final DateTime startTime;
  final List<String> tags;
  final RideSummary summary;
  // No readings, no efforts — lightweight for list display
}
```

### S1.3 AutoLapDetector

```dart
class AutoLapDetector {
  AutoLapDetector(AutoLapConfig config);

  /// Process a single 1Hz merged reading.
  /// Returns null if no state transition occurred.
  /// Returns an event if an effort started or ended.
  /// 
  /// IMPORTANT: Call this exactly once per second, in order.
  /// Null readings (sensor dropout) must still be passed — the detector
  /// handles them internally (they do not trigger state changes).
  AutoLapEvent? processReading(SensorReading reading);

  /// Force a manual lap. Behavior depends on current state:
  ///   Idle → EffortStarted (skip confirmation)
  ///   PendingStart → EffortStarted (confirm immediately)
  ///   InEffort → EffortEnded + EffortStarted (end current, start new)
  ///   PendingEnd → EffortEnded (confirm end immediately)
  /// Returns 1 or 2 events.
  List<AutoLapEvent> manualLap(int currentOffset);

  /// End the ride. Finalizes any in-progress effort.
  /// Returns EffortEnded if in InEffort or PendingEnd state.
  /// Returns null if Idle or PendingStart (tentative discarded).
  AutoLapEvent? endRide(int currentOffset);

  /// Reset all state. Used before re-detection.
  void reset();

  /// Current state for UI display.
  AutoLapState get currentState;

  /// Current pre-effort baseline for UI display.
  double get currentBaseline;
}

enum AutoLapState { idle, pendingStart, inEffort, pendingEnd }

sealed class AutoLapEvent {}

class EffortStartedEvent extends AutoLapEvent {
  final int startOffset;     // backdated to tentative start
  final bool isManual;
  final double preEffortBaseline;
}

class EffortEndedEvent extends AutoLapEvent {
  final int startOffset;     // same as the EffortStartedEvent
  final int endOffset;       // trimmed to tentative end point
  final bool isManual;
  final bool wasTooShort;    // true if < minEffortSeconds (effort discarded)
  final double preEffortBaseline;
  final double peakTrailingAvg;
}
```

### S1.4 MapCurveCalculator

```dart
class MapCurveCalculator {
  /// Batch compute MAP curve from a complete list of readings.
  /// Used: post-ride, re-detection, TCX import.
  /// Readings may contain nulls. See S3 for null handling rules.
  static MapCurve computeBatch(List<SensorReading> readings, String entityId);

  /// Incremental (live) computation. Maintains internal state.
  /// Call once per 1Hz tick with the new reading appended.
  /// Returns updated 90-value curve after each call.
  /// 
  /// Equivalence guarantee: after N calls, the result must be identical
  /// to computeBatch() on the same N readings.
  MapCurve updateLive(SensorReading reading);

  /// Reset internal state. A new instance should be created for each effort.
  /// The live calculator is created when an effort starts and disposed when
  /// it ends. Between efforts, no live calculator exists.
  void reset();
}
```

### S1.5 EffortManager

```dart
class EffortManager {
  /// Creates an Effort from a detected start/end and the ride's readings.
  /// Steps:
  ///   1. Slice readings[startOffset..endOffset]
  ///   2. Compute EffortSummary from slice (peakPower = highest single 1Hz reading)
  ///   3. Compute MapCurve (batch) from slice
  ///   4. Assign effortNumber (1-based, sequential)
  ///   5. Compute restSincePrevious from prior effort's endOffset
  /// Returns fully populated Effort including summary and mapCurve.
  ///
  /// Note: RideSummary is computed separately by SummaryCalculator, which
  /// takes the list of efforts and the full ride readings. Averages (power,
  /// HR, cadence, L/R balance) and totalKilojoules are calculated from
  /// active effort readings only. maxPower and maxHeartRate use the entire ride.
  ///   4. Assign effortNumber (1-based, sequential)
  ///   5. Compute restSincePrevious from prior effort's endOffset
  /// Returns fully populated Effort including summary and mapCurve.
  Effort createEffort({
    required String rideId,
    required int effortNumber,
    required int startOffset,
    required int endOffset,
    required EffortType type,
    required List<SensorReading> rideReadings, // full ride readings
    Effort? previousEffort, // for restSincePrevious
  });

  /// Re-detect all efforts from raw readings with a new config.
  /// Returns the full list of new efforts (not persisted — caller decides).
  List<Effort> redetectEfforts({
    required String rideId,
    required List<SensorReading> readings,
    required AutoLapConfig config,
  });
}
```

### S1.6 ExportService

```dart
class ExportService {
  /// Export ride to TCX file. Returns the file path.
  /// Throws ExportException on validation failure.
  Future<String> exportTcx(Ride ride, List<SensorReading> readings);

  /// Import a single TCX file. Returns a fully populated Ride
  /// including efforts and MAP curves, ready for saveRide().
  /// Source laps are ALWAYS discarded — efforts are re-detected.
  /// Does NOT save to database — caller handles persistence.
  Future<Ride> importTcx(File file, AutoLapConfig config);

  /// Import a ZIP archive of TCX files.
  /// Returns results for each file (success with Ride, or failure with error).
  /// Does NOT save to database — caller handles persistence for each success.
  Future<List<ImportResult>> importZip(File file, AutoLapConfig config);
}

class ImportResult {
  final String fileName;
  final Ride? ride;               // null on failure
  final TcxImportError? error;    // null on success
}

enum ImportErrorType {
  malformedXml,         // unparseable XML
  noTrackpoints,        // valid XML but no usable data
  noPowerData,          // trackpoints exist but no Watts elements
  duplicateRide,        // ride with same startTime already exists
  fileTooLarge,         // > 50MB single file
}
```

### S1.7 HistoricalRangeCalculator

```dart
class HistoricalRangeCalculator {
  /// Compute best and worst envelopes with provenance from a list of
  /// effort-level MAP curves in a single pass.
  ///
  /// Input: MapCurveWithProvenance (curve + effortId, rideId, rideDate,
  /// effortNumber). Output: HistoricalRange with best/worst as
  /// List<PowerDurationRecord>, each tracking which effort produced that
  /// value.
  ///
  /// The best envelope is identical to the PDC for the same span.
  /// Both envelopes are monotonically non-increasing (enforced).
  /// When monotonicity enforcement bumps a value, the provenance is
  /// inherited from the longer duration that provided the higher value.
  ///
  /// Performance: O(n × 90) where n = number of efforts. Single pass.
  /// For 500 efforts this is ~45,000 comparisons — sub-millisecond.
  ///
  /// Caching strategy: Caller (provider) caches the result keyed by
  /// (spanSelection, latestRideId). Invalidated when a new ride is saved
  /// or span selection changes.
  HistoricalRange compute(List<MapCurveWithProvenance> effortCurves);
}
```

---

## S2. Active Ride Sequence Flow

This is the critical orchestration path. The `RideSessionManager` coordinates all components during an active ride.

### S2.1 Ride Start Sequence

```
User taps "Start Ride"
  │
  ├─ If no sensor connected → open DeviceSheet, abort start
  │
  ├─ RideSessionManager.startRide()
  │    ├─ Generate ride UUID
  │    ├─ Record startTime = DateTime.now()
  │    ├─ Initialize AutoLapDetector with current default config
  │    ├─ Create empty readings buffer (in-memory List<SensorReading>)
  │    ├─ Create empty efforts list
  │    ├─ Acquire wakelock
  │    └─ Subscribe to 1Hz merged stream (see S2.2)
  │
  └─ UI transitions to Active Ride screen
```

### S2.2 1Hz Processing Loop (every second)

```
BLE raw notification (1-4 Hz)
  │
  ├─ Accumulated in 1-second bin by RideSessionManager
  │    Power: average all values in bin
  │    HR: last value in bin
  │    Cadence: last value in bin (from CSC delta calc)
  │    No data: null (the SensorReading exists but fields are null)
  │
  ├─ SensorReading created with offsetSeconds = elapsed since ride start
  │
  ├─ Appended to in-memory readings buffer
  │    NOTE: Readings are NOT persisted to DB during the ride.
  │    They are held in memory and batch-written on ride end.
  │    Rationale: avoids 1 DB write/second for potentially 2+ hours.
  │
  ├─ Passed to AutoLapDetector.processReading()
  │    ├─ Returns null → no action
  │    ├─ Returns EffortStartedEvent →
  │    │    ├─ Create new live MapCurveCalculator for this effort
  │    │    ├─ Backfill: feed readings from startOffset to current into the
  │    │    │   live calculator (handles backdating)
  │    │    └─ Notify UI: effort started
  │    └─ Returns EffortEndedEvent →
  │         ├─ If wasTooShort: discard, notify UI briefly, continue
  │         ├─ Else: create Effort via EffortManager.createEffort()
  │         │    (uses readings buffer for the slice)
  │         │    NOTE: createEffort() runs batch MAP computation, which
  │         │    replaces the live curve. The live MapCurveCalculator for
  │         │    this effort is disposed — its output is discarded.
  │         ├─ Append to efforts list
  │         ├─ Dispose live effort MapCurveCalculator
  │         └─ Notify UI: effort ended with summary
  │
  └─ UI update via provider notification
       ├─ Focus mode: current power, phase, elapsed
       ├─ Chart mode: live curve data, previous effort curves
       └─ Both: HR, cadence, connection status
```

### S2.3 Ride End Sequence

```
User long-presses Stop (1.5s confirmation)
  │
  ├─ RideSessionManager.endRide()
  │    ├─ AutoLapDetector.endRide() → may return final EffortEndedEvent
  │    │    If so: create final Effort as in S2.2
  │    │
  │    ├─ Record endTime = DateTime.now()
  │    │
  │    ├─ Compute RideSummary from all readings
  │    │
  │    ├─ Persist to database in a SINGLE TRANSACTION:
  │    │    1. Insert Ride row (with summary fields)
  │    │    2. Batch insert all SensorReadings
  │    │    3. Insert all Efforts (with summary fields)
  │    │    4. Insert all effort MapCurves (90 rows each)
  │    │    NOTE: Ride-level PDC is NOT persisted. It is computed on
  │    │    demand from effort MapCurves when the Ride Detail screen
  │    │    is opened.
  │    │
  │    ├─ Release wakelock
  │    ├─ Clear in-memory buffers
  │    └─ Invalidate historical range cache and maxPowerProvider
  │         (new ride may have set a new all-time 1s best)
  │
  └─ UI transitions to Idle with ride summary
```

### S2.4 App Backgrounding During Active Ride

```
App moves to background (lifecycle event)
  │
  ├─ Ride continues. BLE subscription persists (OS-level).
  │    On iOS: background BLE is supported for connected peripherals
  │    On Android: foreground service required (universal_ble handles this)
  │    On macOS: BLE continues when app window is not focused
  │    On Windows/Linux: BLE via universal_ble continues in background
  │
  ├─ 1Hz processing continues in isolate/background
  │    UI updates are queued but not rendered
  │
  ├─ Wakelock is NOT released (supported on iOS/Android/macOS/Windows; no-op on Linux)
  │
  ├─ If BLE drops during background:
  │    Reconnection logic runs as normal (exponential backoff)
  │    Null readings recorded for gap duration
  │
  └─ On foreground resume: UI catches up from in-memory state
       No data is lost. Provider notifications fire, UI rebuilds.
```

### S2.5 Crash Recovery

```
App crashes or is killed during active ride
  │
  ├─ All in-memory data is LOST. There is no crash recovery in v1.
  │
  ├─ Rationale: Sprint sessions are typically 20-60 minutes.
  │   Crashes are rare. The complexity of periodic checkpointing
  │   is not justified for v1.
  │
  └─ Future consideration (v2): periodic checkpoint writes every 60s
     to a "pending_ride" table, recovered on next app launch.
```

---

## S3. Null Handling Decision Table for MAP Computation

"Null" means sensor dropout — the SensorReading exists (has a timestamp/offset) but `power` is null. See main spec §7.3–7.4 for the algorithm pseudocode including flag tracking.

| Scenario | Duration Counting | Averaging | Example |
|---|---|---|---|
| Effort of 10 readings, all have power | Duration = 10s, avg over 10 | Normal | [500,600,700,...] |
| Effort of 10 readings, 3 are null | Duration = 10s, avg over 7 non-null | Nulls skipped in sum, denominator = non-null count | [500,null,700,null,null,800,...] |
| Window of 5 readings, 2 are null | Window duration = 5s, avg = sum(3 non-null) / 3 | NOT sum/5 | Window [500,null,700,null,800] → avg = 666.7W |
| Window of 5 readings, all null | bestAvg for this window = 0 | 0, not NaN or skip | Window [null,null,null,null,null] → 0W |
| 1s best: single null reading | bestAvg[0] for that offset = 0 | Treated as 0, may be overridden by other windows | N/A — other 1s windows will likely dominate |

### Key implications:

- **Effort duration always includes null seconds.** A 12-second effort with 2 dropouts is a 12s effort, not a 10s effort. The MAP curve has 12 seconds of "opportunity" for windows.
- **MAP window average denominator = non-null count within window.** This means a window with 1 non-null value of 800W over 5 seconds gets avg = 800W (not 160W). This is intentional — we don't penalize the athlete for sensor issues.
- **Monotonicity enforcement runs AFTER null handling.** So if a dropout inflates a longer window's average, the sweep will correct shorter durations upward.

### Prefix sum adaptation for nulls:

```dart
// Standard prefix sum won't work with nulls. Use parallel arrays:
// powerSum[i] = sum of non-null power values in readings[0..i-1]
// countSum[i] = count of non-null power values in readings[0..i-1]
//
// For window [a, b):
//   nonNullCount = countSum[b] - countSum[a]
//   if nonNullCount == 0: avg = 0
//   else: avg = (powerSum[b] - powerSum[a]) / nonNullCount
```

---

## S4. Provider Lifecycle Definitions

| Provider | Dispose Strategy | Rationale |
|---|---|---|
| `bleConnectionProvider` | **keepAlive** | BLE connection persists across all screens |
| `sensorStreamProvider` | **keepAlive** | Stream must not drop during navigation |
| `rideSessionProvider` | **keepAlive** | Active ride must survive navigation to Settings, History, etc. |
| `activeEffortProvider` | **keepAlive** | Derived from rideSessionProvider, same lifecycle |
| `sessionEffortsProvider` | **keepAlive** | Derived from rideSessionProvider |
| `historicalRangeProvider` | **autoDispose** | Single pass via HistoricalRangeCalculator over RideRepository.getAllEffortCurves(). Produces HistoricalRange with provenance on both best and worst. Best envelope doubles as PDC — used by both the ride chart screen (historical band) and the PDC screen (drill-down). Invalidated when span or tag filter changes, or a new ride is saved. |
| `rideListProvider` | **autoDispose** | Queries RideRepository.getRides() filtered by date range from spanSelectionProvider and tags from tagFilterProvider. Requery when History screen is opened, span changes, or tag filter changes. |
| `spanSelectionProvider` | **keepAlive** | Single source of truth for the selected HistorySpan. historicalRangeProvider and rideListProvider depend on this. |
| `tagFilterProvider` | **keepAlive** | Selected tag filters (empty set = show all). historicalRangeProvider and rideListProvider depend on this. |
| `autoLapConfigProvider` | **keepAlive** | Needed by rideSessionProvider at all times |
| `maxPowerProvider` | **keepAlive** | Derived from all-time best 1s (= historicalRangeProvider.best[0] for allTime span with no tag filter), or manual override from settings. Invalidated when a new ride is saved. |
| `deviceListProvider` | **autoDispose** | Requery when Device sheet opens |

### Provider disposal on ride end:

When `rideSessionProvider` transitions from active → idle:
- Internal state (readings buffer, effort list, calculators) is cleared
- The provider itself remains alive (keepAlive) but in idle state
- `activeEffortProvider` and `sessionEffortsProvider` emit empty/null states
- `historicalRangeProvider` is invalidated (if alive) to pick up the new ride

### Provider initialization on app start:

```
1. autoLapConfigProvider → loads default config from DB
2. maxPowerProvider → loads manual override from settings; if null,
   queries all-time PDC 1s best from effort map_curves table
3. bleConnectionProvider → initialized but not scanning
4. rideSessionProvider → initialized in idle state
5. Auto-connect attempt:
   deviceListProvider.getAutoConnectDevices()
   For each: bleConnectionProvider.connect(deviceId)
   Timeout after 5 seconds → remain disconnected (no UI interruption)

Note: historicalRangeProvider and rideListProvider are autoDispose — they
initialize lazily when their respective screens are first opened, not on
app start.
```

---

## S5. Focus/Chart Toggle — Interaction Design

The main spec says "tap anywhere on screen" to toggle Focus ↔ Chart. This is removed — too easy to accidentally toggle when trying to tap LAP/STOP, and too easy to miss buttons.

### Resolution: Swipe, keyboard, or segmented control. No tap-to-toggle on empty areas.

```
Focus ↔ Chart toggle (compact/medium layout only):
  METHODS:
    1. Horizontal swipe (left = chart, right = focus) — min 80px movement
    2. Left/right arrow keys (keyboard)
    3. Segmented control pills at top (tap/click)

  NO tap-to-toggle on empty screen areas. Tap is reserved exclusively
  for buttons and interactive elements.

Interactive elements (consume tap/click):
  LAP button (or Space key)
  STOP button (long-press, or Escape key → confirmation dialog)
  Chart tooltip interaction points
  Mode toggle pills at top (explicit Focus / Chart segmented control)
```

The segmented control pills at the top of the active ride screen serve as a visible affordance and a fallback for users who don't discover the swipe gesture or keyboard shortcuts.

On expanded layout (≥ 900dp), Focus and Chart are shown side-by-side — no toggle is needed.

---

## S6. Re-detection Preview UI

When user taps "Re-detect efforts" on Ride Detail:

```
1. Show config selector (same as Settings auto-lap config)
2. On config change or "Preview" tap:
   a. Run EffortManager.redetectEfforts() with new config
   b. Display comparison view:
   
   ┌─────────────────────────────────┐
   │ Re-detect Efforts               │
   │                                 │
   │ Current: 4 efforts              │
   │ ████░░████░░░████░░████         │  ← colored bars on power timeline
   │                                 │
   │ Preview: 6 efforts              │
   │ ██░██░░██░░░██░██░░██░██        │  ← different segmentation
   │                                 │
   │ Changes:                        │
   │  • Effort 2 split into 2-3     │
   │  • Effort 4 split into 5-6     │
   │  • New effort durations:        │
   │    6s, 5s, 11s, 13s, 4s, 6s   │
   │                                 │
   │ [Cancel]  [Make Default]  [Apply]  │
   └─────────────────────────────────────┘

3. "Apply" replaces efforts in DB:
   a. Delete old efforts and their map_curves
   b. Save new efforts and map_curves
   c. Update ride.autoLapConfigId
   d. Update ride.effortCount in summary
   e. Invalidate historical range cache
   f. Navigate back to Ride Detail (refreshed)

4. "Make Default" (optional, can be combined with Apply):
   a. Save the previewed config as the app-wide default
   b. Sets isDefault=true on this config, isDefault=false on previous default
```

---

## S7. TCX Timezone Handling

### Export:
- All timestamps are absolute: `ride.startTime + reading.offsetSeconds`
- Output in UTC with `Z` suffix: `2026-02-28T14:30:15Z`
- Ride's local timezone is NOT embedded in TCX (not supported by format)

### Import:

| TCX Timestamp Format | Interpretation |
|---|---|
| `2026-02-28T14:30:15Z` | UTC, convert to local for display |
| `2026-02-28T14:30:15+02:00` | Explicit offset, convert to UTC for storage |
| `2026-02-28T14:30:15` (no zone) | **Assume UTC.** Log a warning. |
| Unparseable timestamp | Skip this trackpoint. Log error. Continue. |

### Deduplication on import:
- A ride is considered a duplicate if another ride exists with the same `startTime` (within ±2 seconds) AND the same `readingCount` (within ±5%).
- Duplicate detection happens BEFORE full parsing to save time.
- On duplicate: return `ImportError.duplicateRide` with the existing ride ID.

---

## S8. Error Types

```dart
/// All domain-level errors. Presentation layer maps these to user-facing messages.

sealed class AppError {}

// BLE
class BleConnectionError extends AppError {
  final String deviceId;
  final String reason; // "timeout", "not_found", "rejected", "unknown"
}
class BleScanError extends AppError {
  final String reason; // "permission_denied", "bluetooth_off", "unknown"
}

// Database
class DatabaseError extends AppError {
  final String operation; // "save_ride", "query_rides", etc.
  final String detail;
}

// Import/Export
class TcxImportError extends AppError {
  final String fileName;
  final ImportErrorType type;
  final String? detail;
}
class ExportError extends AppError {
  final String rideId;
  final String reason;
}

// Domain
class InvalidConfigError extends AppError {
  final String field;
  final String reason;
}
```

---

## S9. Implementation Order for AI Agent

Recommended order to minimize rework and enable incremental testing:

### Phase 1: Foundation (no UI)
1. **Data models** — All pure Dart classes from §4 of main spec. Note: there is no RiderProfile model in v1. maxPower is stored in app_settings, not a dedicated model. DurationRecord is the per-duration struct used in HistoricalRange best/worst.
2. **MapCurveCalculator** — Batch + live, with full test suite (including flags)
3. **SummaryCalculator** — With null handling tests, active-effort-only ride summary
4. **AutoLapDetector** — Full state machine with all edge case tests
5. **EffortManager** — Depends on 2, 3, 4
6. **HistoricalRangeCalculator** — Single pass best/worst with provenance. Depends on monotonicity from 2

### Phase 2: Data Layer
7. **Database schema + Drift codegen** — All tables from §5 including ride_tags
8. **LocalRideRepository** — Implements RideRepository interface including tag queries
9. **BLE Profile Parsers** — Stateless, test with byte fixtures
10. **BleServiceImpl** — Connection state machine, reconnection logic
11. **TcxSerializer + TcxParser** — Round-trip tests

### Phase 3: Orchestration
12. **RideSessionManager** — The hardest piece. Depends on 2-5, 8, 10
13. **ExportService** — Depends on 8, 11

### Phase 4: Presentation
14. **Riverpod providers** — Wire up domain to UI
15. **Ride Screen** — Idle, Focus, Chart modes
16. **Device Connection Sheet**
17. **History + Ride Detail screens**
18. **PDC screen**
19. **Settings + Auto-Lap Config screen**

### Phase 4b: Desktop Support
20. **Platform scaffolding** — Generate macOS/Windows/Linux/Android dirs, BLE entitlements, min window size
21. **Responsive layout** — Breakpoints, AdaptiveShell (nav rail vs bottom nav), LayoutBuilder in RideScreen
22. **Keyboard shortcuts** — Intent classes, shortcut map, Focus widget wiring
23. **Desktop interaction polish** — Mouse cursors, tooltips with shortcut hints, adaptive device dialog

### Phase 5: Polish
24. **Orientation handling** — smooth transitions on mobile rotation and desktop window resize
25. **Animations and transitions**
26. **Re-detection preview**
27. **Bulk import UI**

Each phase should be fully tested before moving to the next. The agent should run `dart test` / `flutter test` after completing each numbered item.
