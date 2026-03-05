# Wattalizer – AI Implementation Guide

This document provides concrete code patterns, pseudocode, examples, and file structures to supplement the main spec and spec supplement. It is designed to eliminate ambiguity for an AI coding agent.

---

## IG1. Complete File Tree

```
lib/
  main.dart                           — app entry point, ProviderScope
  
  core/
    constants.dart                    — durations (1..90), default config values
    error_types.dart                  — AppError sealed class hierarchy
    extensions.dart                   — Dart extension methods (DateTime, List, etc.)
  
  data/
    ble/
      ble_service_impl.dart           — implements BleService using flutter_reactive_ble
      power_parser.dart               — stateless, bytes → PowerData
      hr_parser.dart                  — stateless, bytes → HeartRateData
      csc_parser.dart                 — stateful, bytes → CadenceData (delta-based)
      raw_sensor_data.dart            — RawSensorData class
    database/
      database.dart                   — Drift database class, migration strategy
      tables.dart                     — all Drift table definitions
      local_ride_repository.dart      — implements RideRepository
    tcx/
      tcx_serializer.dart             — Ride + readings → TCX XML string
      tcx_parser.dart                 — TCX XML string → Ride + readings
  
  domain/
    models/
      sensor_reading.dart             — SensorReading
      ride.dart                       — Ride, RideSource enum
      effort.dart                     — Effort, EffortType enum
      ride_summary.dart               — RideSummary
      effort_summary.dart             — EffortSummary
      map_curve.dart                  — MapCurve, MapCurveFlags
      historical_range.dart           — HistoricalRange, DurationRecord
      device_info.dart                — DeviceInfo, SensorType enum
      autolap_config.dart             — AutoLapConfig, presets
      history_span.dart               — HistorySpan enum (week, month, year, allTime)
      tag_count.dart                  — TagCount
    interfaces/
      ble_service.dart                — abstract BleService
      ride_repository.dart            — abstract RideRepository
    services/
      ride_session_manager.dart       — orchestrates active rides
      autolap_detector.dart           — AutoLapDetector state machine
      rolling_baseline.dart           — RollingBaseline helper class
      effort_manager.dart             — creates/re-detects efforts
      map_curve_calculator.dart       — batch + live MAP computation
      historical_range_calculator.dart — best/worst envelopes with provenance
      summary_calculator.dart         — ride and effort summaries
      export_service.dart             — import/export orchestration
    events/
      autolap_events.dart             — EffortStartedEvent, EffortEndedEvent
  
  presentation/
    providers/
      ble_connection_provider.dart
      sensor_stream_provider.dart
      ride_session_provider.dart
      active_effort_provider.dart
      session_efforts_provider.dart
      historical_range_provider.dart
      ride_list_provider.dart
      span_selection_provider.dart
      tag_filter_provider.dart
      autolap_config_provider.dart
      max_power_provider.dart
    screens/
      ride_screen.dart                — primary/home, idle + active states
      ride_screen_focus.dart          — focus mode widget
      ride_screen_chart.dart          — chart mode widget
      history_screen.dart
      ride_detail_screen.dart
      pdc_screen.dart                 — power duration curve
      settings_screen.dart
      autolap_config_screen.dart
    widgets/
      map_curve_chart.dart            — reusable MAP/PDC chart
      device_sheet.dart               — bottom sheet for BLE devices
      effort_card.dart                — expandable effort card
      effort_timeline.dart            — horizontal colored bar
      tag_input.dart                  — tag chips + autocomplete
      power_display.dart              — large power number with color
      sparkline.dart                  — mini power trace

test/
  domain/
    map_curve_calculator_test.dart
    autolap_detector_test.dart
    rolling_baseline_test.dart
    historical_range_calculator_test.dart
    summary_calculator_test.dart
    effort_manager_test.dart
  data/
    power_parser_test.dart
    hr_parser_test.dart
    csc_parser_test.dart
    local_ride_repository_test.dart
    tcx_serializer_test.dart
    tcx_parser_test.dart
    tcx_round_trip_test.dart
  presentation/
    ride_screen_test.dart
    providers_test.dart
```

---

## IG2. RollingBaseline — Complete Implementation

This class is used by AutoLapDetector for both pre-effort and in-effort baselines.

```dart
/// A rolling average over a fixed-size window of power readings.
/// Supports freeze (stop updating), unfreeze (resume), and clear (reset).
class RollingBaseline {
  final int windowSize;
  final List<double> _buffer = [];
  int _writeIndex = 0;
  bool _isFull = false;
  bool _frozen = false;

  RollingBaseline(this.windowSize);

  /// Add a reading. Ignored if frozen or value is null.
  void add(double? value) {
    if (_frozen || value == null) return;
    if (_buffer.length < windowSize) {
      _buffer.add(value);
    } else {
      _buffer[_writeIndex] = value;
    }
    _writeIndex = (_writeIndex + 1) % windowSize;
    if (_buffer.length == windowSize) _isFull = true;
  }

  /// Current average. Returns 0.0 if buffer is empty.
  double get average {
    if (_buffer.isEmpty) return 0.0;
    double sum = 0.0;
    for (final v in _buffer) sum += v;
    return sum / _buffer.length;
  }

  /// Stop accepting new values. Average stays at last computed value.
  void freeze() => _frozen = true;

  /// Resume accepting new values.
  void unfreeze() => _frozen = false;

  /// Reset to empty state. Also unfreezes.
  void clear() {
    _buffer.clear();
    _writeIndex = 0;
    _isFull = false;
    _frozen = false;
  }

  bool get isFrozen => _frozen;
  bool get isEmpty => _buffer.isEmpty;
}
```

---

## IG3. AutoLapDetector — Complete Pseudocode

```dart
class AutoLapDetector {
  final AutoLapConfig config;
  AutoLapState _state = AutoLapState.idle;
  
  late RollingBaseline _preEffortBaseline;
  late RollingBaseline _inEffortTrailing;
  
  int _tentativeStartOffset = 0;
  int _tentativeEndOffset = 0;
  int _confirmCount = 0;
  int _dropoutCount = 0;

  AutoLapDetector(this.config) {
    _preEffortBaseline = RollingBaseline(config.preEffortBaselineWindow);
    _inEffortTrailing = RollingBaseline(config.inEffortTrailingWindow);
  }

  AutoLapState get currentState => _state;
  double get currentBaseline => _preEffortBaseline.average;

  AutoLapEvent? processReading(SensorReading reading) {
    final power = reading.power;  // may be null
    final offset = reading.timestamp.inSeconds;

    switch (_state) {
      case AutoLapState.idle:
        // Feed baseline (ignores nulls internally)
        _preEffortBaseline.add(power);
        
        // Check for sprint start
        if (power != null && power > _preEffortBaseline.average + config.startDeltaWatts) {
          _state = AutoLapState.pendingStart;
          _tentativeStartOffset = offset;
          _confirmCount = 1;
          _dropoutCount = 0;
          _preEffortBaseline.freeze();
        }
        return null;

      case AutoLapState.pendingStart:
        if (power == null) {
          // Null readings don't count for or against confirmation
          return null;
        }
        
        if (power > _preEffortBaseline.average + config.startDeltaWatts) {
          _confirmCount++;
        } else {
          _dropoutCount++;
        }
        
        // Too many dropouts — false alarm
        if (_dropoutCount > config.startDropoutTolerance) {
          _state = AutoLapState.idle;
          _preEffortBaseline.unfreeze();
          return null;
        }
        
        // Confirmed — transition to InEffort
        if (_confirmCount >= config.startConfirmSeconds) {
          _state = AutoLapState.inEffort;
          _inEffortTrailing.clear();
          // Backfill: trailing baseline starts from tentative start
          // (caller handles feeding historical readings to trailing)
          _inEffortTrailing.add(power);
          return EffortStartedEvent(
            startOffset: _tentativeStartOffset,  // backdated
            isManual: false,
            preEffortBaseline: _preEffortBaseline.average,
          );
        }
        return null;

      case AutoLapState.inEffort:
        // Feed trailing average (ignores nulls internally)
        _inEffortTrailing.add(power);
        
        // Check for sprint end
        if (power != null && power < _inEffortTrailing.average - config.endDeltaWatts) {
          _state = AutoLapState.pendingEnd;
          _tentativeEndOffset = offset;
          _confirmCount = 1;
          _inEffortTrailing.freeze();
        }
        return null;

      case AutoLapState.pendingEnd:
        if (power == null) {
          // Null readings don't count for or against
          return null;
        }
        
        if (power < _inEffortTrailing.average - config.endDeltaWatts) {
          _confirmCount++;
        } else {
          // Power came back up — not a real end
          _state = AutoLapState.inEffort;
          _inEffortTrailing.unfreeze();
          _inEffortTrailing.add(power);
          return null;
        }
        
        // Confirmed end
        if (_confirmCount >= config.endConfirmSeconds) {
          _state = AutoLapState.idle;
          _preEffortBaseline.clear();  // reset for next effort
          _inEffortTrailing.clear();
          
          final duration = _tentativeEndOffset - _tentativeStartOffset;
          final tooShort = duration < config.minEffortSeconds;
          
          return EffortEndedEvent(
            startOffset: _tentativeStartOffset,
            endOffset: _tentativeEndOffset,  // trimmed to tentative
            isManual: false,
            wasTooShort: tooShort,
            preEffortBaseline: _preEffortBaseline.average,
            peakTrailingAvg: _inEffortTrailing.average,
          );
        }
        return null;
    }
  }

  List<AutoLapEvent> manualLap(int currentOffset) {
    switch (_state) {
      case AutoLapState.idle:
        _preEffortBaseline.freeze();
        _inEffortTrailing.clear();
        _tentativeStartOffset = currentOffset;
        _state = AutoLapState.inEffort;
        return [EffortStartedEvent(
          startOffset: currentOffset,
          isManual: true,
          preEffortBaseline: _preEffortBaseline.average,
        )];

      case AutoLapState.pendingStart:
        // Confirm immediately
        _state = AutoLapState.inEffort;
        _inEffortTrailing.clear();
        return [EffortStartedEvent(
          startOffset: _tentativeStartOffset,
          isManual: true,
          preEffortBaseline: _preEffortBaseline.average,
        )];

      case AutoLapState.inEffort:
        // End current + start new
        final endEvent = EffortEndedEvent(
          startOffset: _tentativeStartOffset,
          endOffset: currentOffset,
          isManual: true,
          wasTooShort: false,  // manual overrides min duration
          preEffortBaseline: _preEffortBaseline.average,
          peakTrailingAvg: _inEffortTrailing.average,
        );
        _preEffortBaseline.clear();
        _inEffortTrailing.clear();
        _tentativeStartOffset = currentOffset;
        // State stays inEffort
        final startEvent = EffortStartedEvent(
          startOffset: currentOffset,
          isManual: true,
          preEffortBaseline: 0.0,  // just cleared
        );
        return [endEvent, startEvent];

      case AutoLapState.pendingEnd:
        // Confirm end immediately
        _state = AutoLapState.idle;
        _preEffortBaseline.clear();
        _inEffortTrailing.clear();
        return [EffortEndedEvent(
          startOffset: _tentativeStartOffset,
          endOffset: _tentativeEndOffset,
          isManual: true,
          wasTooShort: false,
          preEffortBaseline: _preEffortBaseline.average,
          peakTrailingAvg: _inEffortTrailing.average,
        )];
    }
  }

  AutoLapEvent? endRide(int currentOffset) {
    switch (_state) {
      case AutoLapState.idle:
        return null;
      case AutoLapState.pendingStart:
        // Discard tentative
        _state = AutoLapState.idle;
        return null;
      case AutoLapState.inEffort:
        _state = AutoLapState.idle;
        return EffortEndedEvent(
          startOffset: _tentativeStartOffset,
          endOffset: currentOffset,
          isManual: false,
          wasTooShort: false,  // skip min duration check on ride end
          preEffortBaseline: _preEffortBaseline.average,
          peakTrailingAvg: _inEffortTrailing.average,
        );
      case AutoLapState.pendingEnd:
        _state = AutoLapState.idle;
        return EffortEndedEvent(
          startOffset: _tentativeStartOffset,
          endOffset: _tentativeEndOffset,
          isManual: false,
          wasTooShort: false,
          preEffortBaseline: _preEffortBaseline.average,
          peakTrailingAvg: _inEffortTrailing.average,
        );
    }
  }

  void reset() {
    _state = AutoLapState.idle;
    _preEffortBaseline.clear();
    _inEffortTrailing.clear();
    _confirmCount = 0;
    _dropoutCount = 0;
  }
}
```

---

## IG4. MapCurveCalculator — Complete Implementation

### IG4.1 Batch Computation with Null Handling and Flags

```dart
class MapCurveCalculator {
  // --- Batch ---
  static MapCurve computeBatch(List<SensorReading> readings, String entityId) {
    final n = readings.length;
    final values = List<double>.filled(90, 0.0);
    final flags = List<MapCurveFlags>.generate(90, (_) => MapCurveFlags());

    if (n == 0) {
      return MapCurve(
        entityId: entityId,
        values: values,
        flags: flags,
        computedAt: DateTime.now(),
      );
    }

    // Build parallel prefix sums for null handling
    // powerSum[i] = sum of non-null power in readings[0..i-1]
    // countSum[i] = count of non-null power in readings[0..i-1]
    final powerSum = List<double>.filled(n + 1, 0.0);
    final countSum = List<int>.filled(n + 1, 0);

    for (int i = 0; i < n; i++) {
      final p = readings[i].power;
      powerSum[i + 1] = powerSum[i] + (p ?? 0.0);
      countSum[i + 1] = countSum[i] + (p != null ? 1 : 0);
    }

    // For each duration d (1..90), find the best window average
    for (int d = 1; d <= 90; d++) {
      double bestAvg = 0.0;
      bool bestHadNulls = false;

      if (d > n) {
        // Duration longer than data — use entire data as single window
        final nonNull = countSum[n];
        if (nonNull > 0) {
          bestAvg = powerSum[n] / nonNull;
          bestHadNulls = nonNull < n;
        }
      } else {
        // Slide window of size d across all positions
        for (int end = d; end <= n; end++) {
          final start = end - d;
          final nonNull = countSum[end] - countSum[start];

          if (nonNull == 0) continue;  // all-null window → 0, skip

          final avg = (powerSum[end] - powerSum[start]) / nonNull;
          if (avg > bestAvg) {
            bestAvg = avg;
            bestHadNulls = nonNull < d;
          }
        }
      }

      values[d - 1] = bestAvg;
      flags[d - 1] = MapCurveFlags(hadNulls: bestHadNulls, wasEnforced: false);
    }

    // Monotonicity enforcement: sweep right-to-left
    for (int i = 88; i >= 0; i--) {
      if (values[i] < values[i + 1]) {
        values[i] = values[i + 1];
        flags[i] = MapCurveFlags(
          hadNulls: flags[i].hadNulls || flags[i + 1].hadNulls,
          wasEnforced: true,
        );
      }
    }

    return MapCurve(
      entityId: entityId,
      values: values,
      flags: flags,
      computedAt: DateTime.now(),
    );
  }

  // --- Live (incremental) ---
  final List<double?> _readings = [];
  final List<double> _powerSum = [0.0];
  final List<int> _countSum = [0];

  MapCurve updateLive(SensorReading reading, String entityId) {
    // Append new reading
    _readings.add(reading.power);
    final p = reading.power;
    _powerSum.add(_powerSum.last + (p ?? 0.0));
    _countSum.add(_countSum.last + (p != null ? 1 : 0));

    final n = _readings.length;
    final values = List<double>.filled(90, 0.0);
    final flags = List<MapCurveFlags>.generate(90, (_) => MapCurveFlags());

    // Only need to check windows ending at the latest position
    // PLUS carry forward previous best for each duration
    // For correctness, we do full recompute. For O(90) optimization,
    // maintain a _bestValues array and only check new windows.
    // Full recompute shown here for clarity and equivalence guarantee.
    for (int d = 1; d <= 90; d++) {
      double bestAvg = 0.0;
      bool bestHadNulls = false;

      for (int end = d; end <= n; end++) {
        final start = end - d;
        final nonNull = _countSum[end] - _countSum[start];
        if (nonNull == 0) continue;
        final avg = (_powerSum[end] - _powerSum[start]) / nonNull;
        if (avg > bestAvg) {
          bestAvg = avg;
          bestHadNulls = nonNull < d;
        }
      }

      values[d - 1] = bestAvg;
      flags[d - 1] = MapCurveFlags(hadNulls: bestHadNulls, wasEnforced: false);
    }

    // Monotonicity enforcement
    for (int i = 88; i >= 0; i--) {
      if (values[i] < values[i + 1]) {
        values[i] = values[i + 1];
        flags[i] = MapCurveFlags(
          hadNulls: flags[i].hadNulls || flags[i + 1].hadNulls,
          wasEnforced: true,
        );
      }
    }

    return MapCurve(
      entityId: entityId,
      values: values,
      flags: flags,
      computedAt: DateTime.now(),
    );
  }

  void reset() {
    _readings.clear();
    _powerSum
      ..clear()
      ..add(0.0);
    _countSum
      ..clear()
      ..add(0);
  }
}
```

### IG4.2 Worked Example

Input readings (6 seconds): `[100, 800, null, null, 500, 600]`

**Prefix sums:**
```
index:     0    1    2    3    4    5    6
powerSum:  0  100  900  900  900 1400 2000
countSum:  0    1    2    2    2    3    4
```

**1s best:** Check each single reading:
- [100]=100, [800]=800, [null]=skip, [null]=skip, [500]=500, [600]=600
- Best: **800W**, hadNulls: false

**2s best:** Check each 2-wide window:
- [100,800]: nonNull=2, avg=900/2=450
- [800,null]: nonNull=1, avg=800/1=800
- [null,null]: nonNull=0, skip
- [null,500]: nonNull=1, avg=500/1=500
- [500,600]: nonNull=2, avg=1100/2=550
- Best: **800W**, hadNulls: true (window [800,null] had 1<2)

**3s best:**
- [100,800,null]: nonNull=2, avg=900/2=450
- [800,null,null]: nonNull=1, avg=800/1=800
- [null,null,500]: nonNull=1, avg=500/1=500
- [null,500,600]: nonNull=2, avg=1100/2=550
- Best: **800W**, hadNulls: true

**4s best:**
- [100,800,null,null]: nonNull=2, avg=900/2=450
- [800,null,null,500]: nonNull=2, avg=1300/2=650
- [null,null,500,600]: nonNull=2, avg=1100/2=550
- Best: **650W**, hadNulls: true

**5s best:**
- [100,800,null,null,500]: nonNull=3, avg=1400/3=466.7
- [800,null,null,500,600]: nonNull=3, avg=1900/3=633.3
- Best: **633.3W**, hadNulls: true

**6s best:**
- [100,800,null,null,500,600]: nonNull=4, avg=2000/4=500
- Best: **500W**, hadNulls: true

**Before monotonicity:** `[800, 800, 800, 650, 633.3, 500]`

**Monotonicity sweep (right-to-left):**
- i=4: 633.3 > 500 ✓
- i=3: 650 > 633.3 ✓
- i=2: 800 > 650 ✓
- i=1: 800 = 800 ✓
- i=0: 800 = 800 ✓

**After:** `[800, 800, 800, 650, 633.3, 500]` — no enforcement needed in this example.

---

## IG5. HistoricalRangeCalculator — Worked Example

**Input:** 3 efforts with cached MapCurves (showing first 5 durations only for brevity):

```
Effort A (ride R1, 2026-02-20, effort #1):
  curve: [1400, 1300, 1200, 1100, 1000]

Effort B (ride R1, 2026-02-20, effort #2):
  curve: [1350, 1280, 1250, 1150, 1050]

Effort C (ride R2, 2026-02-24, effort #1):
  curve: [1420, 1290, 1180, 1080, 980]
```

**Single-pass algorithm:**

```
For each duration d (0..4):
  best[d] = max across all efforts at index d, track which effort
  worst[d] = min across all efforts at index d, track which effort

d=0 (1s): max=1420 (C), min=1350 (B)
d=1 (2s): max=1300 (A), min=1280 (B)
d=2 (3s): max=1250 (B), min=1180 (C)
d=3 (4s): max=1150 (B), min=1080 (C)
d=4 (5s): max=1050 (B), min=980 (C)
```

**Best envelope (= PDC):**
```
[1420, 1300, 1250, 1150, 1050]
  C      A      B      B      B
```

**Worst envelope:**
```
[1350, 1280, 1180, 1080, 980]
  B      B      C      C      C
```

**Monotonicity check on best:** 1420 ≥ 1300 ≥ 1250 ≥ 1150 ≥ 1050 ✓
**Monotonicity check on worst:** 1350 ≥ 1280 ≥ 1180 ≥ 1080 ≥ 980 ✓

If enforcement were needed (e.g., worst[2]=1300 but worst[3]=1080), the bumped value inherits provenance from the longer duration:
```
worst[2] was 1300, worst[3] is 1080
1300 > 1080, so no bump needed.

But hypothetically if worst[2]=1050 and worst[3]=1080:
  worst[2] gets bumped to 1080
  worst[2].provenance = worst[3].provenance (effort C)
```

---

## IG6. 1Hz Merge — Worked Example

**Raw BLE notifications in one second (t=4.0s to t=5.0s):**

```
t=4.10s: Power=850W, HR=null, Cadence=null
t=4.35s: Power=920W, HR=172bpm, Cadence=null
t=4.60s: Power=880W, HR=null, Cadence=118rpm
t=4.85s: Power=910W, HR=175bpm, Cadence=120rpm
```

**Merge rules:**
- Power: average all → (850 + 920 + 880 + 910) / 4 = **890W**
- Heart rate: last value → **175bpm** (from t=4.85s)
- Cadence: last value → **120rpm** (from t=4.85s)

**Resulting SensorReading:**
```dart
SensorReading(
  timestamp: Duration(seconds: 4),  // offset from ride start
  power: 890.0,
  heartRate: 175,
  cadence: 120.0,
  // all other fields from the last notification that had them
)
```

**If no notifications arrive in a 1-second bin:**
```dart
SensorReading(
  timestamp: Duration(seconds: 4),
  power: null,      // NOT 0 — null means dropout
  heartRate: null,
  cadence: null,
)
```

---

## IG7. TCX File — Minimal Complete Example

### IG7.1 Export Example (3 trackpoints, 1 effort)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase
  xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
  xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
  <Activities>
    <Activity Sport="Biking">
      <Id>2026-02-28T08:41:00Z</Id>
      
      <!-- Effort lap (Active) -->
      <Lap StartTime="2026-02-28T08:41:05Z">
        <TotalTimeSeconds>3</TotalTimeSeconds>
        <Intensity>Active</Intensity>
        <TriggerMethod>Manual</TriggerMethod>
        <Track>
          <Trackpoint>
            <Time>2026-02-28T08:41:05Z</Time>
            <HeartRateBpm><Value>168</Value></HeartRateBpm>
            <Cadence>115</Cadence>
            <Extensions>
              <ns3:TPX><ns3:Watts>1200</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2026-02-28T08:41:06Z</Time>
            <HeartRateBpm><Value>172</Value></HeartRateBpm>
            <Cadence>120</Cadence>
            <Extensions>
              <ns3:TPX><ns3:Watts>1380</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2026-02-28T08:41:07Z</Time>
            <!-- No HR this second (dropout) — element omitted entirely -->
            <Cadence>118</Cadence>
            <Extensions>
              <ns3:TPX><ns3:Watts>1290</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
        </Track>
      </Lap>
      
      <!-- Recovery lap (Resting) -->
      <Lap StartTime="2026-02-28T08:41:08Z">
        <TotalTimeSeconds>2</TotalTimeSeconds>
        <Intensity>Resting</Intensity>
        <TriggerMethod>Manual</TriggerMethod>
        <Track>
          <Trackpoint>
            <Time>2026-02-28T08:41:08Z</Time>
            <HeartRateBpm><Value>175</Value></HeartRateBpm>
            <Cadence>80</Cadence>
            <Extensions>
              <ns3:TPX><ns3:Watts>120</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2026-02-28T08:41:09Z</Time>
            <HeartRateBpm><Value>173</Value></HeartRateBpm>
            <!-- No Watts this second — element omitted = null power (dropout) -->
            <!-- NOT <ns3:Watts>0</ns3:Watts> which means coasting -->
          </Trackpoint>
        </Track>
      </Lap>
      
    </Activity>
  </Activities>
</TrainingCenterDatabase>
```

### IG7.2 Import Parsing Rules

```
1. Find all <Trackpoint> elements regardless of which <Lap> they're in
2. Sort by <Time> ascending
3. For each trackpoint:
   - time → compute offsetSeconds from first trackpoint's time
   - <Extensions>/<ns3:TPX>/<ns3:Watts> → power (double)
     - Element present with value: power = value (0 = coasting, valid)
     - Element missing: power = null (dropout)
   - <HeartRateBpm>/<Value> → heartRate (int)
     - Element missing: heartRate = null
   - <Cadence> → cadence (double)
     - Element missing: cadence = null
4. Ignore all <Lap> structure — discard Intensity, TotalTimeSeconds, etc.
5. Detect namespace prefix dynamically:
   - Look for any xmlns attribute containing "ActivityExtension/v2"
   - Use that prefix for Watts extraction
   - Common prefixes: ns3, tpx, ax2, or default namespace
```

---

## IG8. Drift Table Definition — Reference Pattern

One table shown in actual Drift Dart syntax. Use this pattern for all tables.

```dart
// In tables.dart

class Rides extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text()();  // 'recorded' or 'imported_tcx'
  TextColumn get autoLapConfigId => text().nullable()
      .references(AutolapConfigs, #id)();
  IntColumn get durationSeconds => integer()();
  IntColumn get activeDurationSeconds => integer()();
  RealColumn get avgPower => real()();
  RealColumn get maxPower => real()();
  IntColumn get avgHeartRate => integer().nullable()();
  IntColumn get maxHeartRate => integer().nullable()();
  RealColumn get avgCadence => real().nullable()();
  RealColumn get totalKilojoules => real()();
  RealColumn get avgLeftRightBalance => real().nullable()();
  IntColumn get readingCount => integer()();
  IntColumn get effortCount => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class RideTags extends Table {
  TextColumn get rideId => text().references(Rides, #id)();
  TextColumn get tag => text()();

  @override
  Set<Column> get primaryKey => {rideId, tag};
}

class Efforts extends Table {
  TextColumn get id => text()();
  TextColumn get rideId => text().references(Rides, #id)();
  IntColumn get effortNumber => integer()();
  IntColumn get startOffset => integer()();
  IntColumn get endOffset => integer()();
  TextColumn get type => text()();  // 'auto' or 'manual'
  IntColumn get durationSeconds => integer()();
  RealColumn get avgPower => real()();
  RealColumn get peakPower => real()();
  IntColumn get avgHeartRate => integer().nullable()();
  IntColumn get maxHeartRate => integer().nullable()();
  RealColumn get avgCadence => real().nullable()();
  RealColumn get totalKilojoules => real()();
  RealColumn get avgLeftRightBalance => real().nullable()();
  IntColumn get restSincePrevious => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MapCurves extends Table {
  TextColumn get effortId => text().references(Efforts, #id)();
  IntColumn get durationSeconds => integer()();
  RealColumn get bestAvgPower => real()();
  BoolColumn get hadNulls => boolean().withDefault(const Constant(false))();
  BoolColumn get wasEnforced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {effortId, durationSeconds};
}

// Database class
@DriftDatabase(tables: [
  Rides, RideTags, Efforts, Readings, MapCurves,
  AutolapConfigs, Devices, AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Future migrations go here
    },
  );
}
```

---

## IG9. Error Handling Pattern

**Pattern: repository throws → provider catches → UI shows**

```dart
// 1. Repository throws typed error
class LocalRideRepository implements RideRepository {
  @override
  Future<void> saveRide(Ride ride) async {
    try {
      await _db.transaction(() async {
        await _db.into(_db.rides).insert(ride.toCompanion());
        // ... batch insert readings, efforts, etc.
      });
    } catch (e) {
      throw DatabaseError(operation: 'save_ride', detail: e.toString());
    }
  }
}

// 2. Provider catches and exposes as AsyncValue
final rideSessionProvider = StateNotifierProvider<RideSessionNotifier, RideState>((ref) {
  return RideSessionNotifier(ref.read(rideRepositoryProvider));
});

class RideSessionNotifier extends StateNotifier<RideState> {
  Future<void> endRide() async {
    try {
      // ... compute summaries, efforts, etc.
      await _repository.saveRide(ride);
      state = RideState.idle(lastRide: ride);
    } on DatabaseError catch (e) {
      state = RideState.error('Failed to save ride: ${e.detail}');
    } on AppError catch (e) {
      state = RideState.error('Unexpected error: $e');
    }
  }
}

// 3. UI reacts to state
// In ride_screen.dart:
Widget build(BuildContext context) {
  final rideState = ref.watch(rideSessionProvider);
  return switch (rideState) {
    RideStateIdle() => IdleView(...),
    RideStateActive() => ActiveView(...),
    RideStateError(:final message) => ErrorView(message: message),
  };
}
```

---

## IG10. Test Conventions

### File naming
- Test file mirrors source file: `lib/domain/services/foo.dart` → `test/domain/foo_test.dart`
- One test file per source file

### Test structure
```dart
// test/domain/map_curve_calculator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/services/map_curve_calculator.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

void main() {
  group('MapCurveCalculator.computeBatch', () {
    test('known sequence produces expected values', () {
      final readings = [
        _reading(0, power: 500),
        _reading(1, power: 800),
        _reading(2, power: 600),
      ];
      final curve = MapCurveCalculator.computeBatch(readings, 'test');

      expect(curve.values[0], 800.0);   // 1s best = max
      expect(curve.values[1], 700.0);   // 2s best = (800+600)/2
      expect(curve.values[2], 633.33, matcher: closeTo(633.33, 0.01));
    });

    test('all null readings produce all zeros', () {
      final readings = [
        _reading(0, power: null),
        _reading(1, power: null),
      ];
      final curve = MapCurveCalculator.computeBatch(readings, 'test');

      for (final v in curve.values) {
        expect(v, 0.0);
      }
    });

    test('output is monotonically non-increasing', () {
      // Property-based: any random input should produce non-increasing output
      final rng = Random(42);
      final readings = List.generate(30, (i) =>
        _reading(i, power: rng.nextDouble() * 1500));
      final curve = MapCurveCalculator.computeBatch(readings, 'test');

      for (int i = 0; i < 89; i++) {
        expect(curve.values[i], greaterThanOrEqualTo(curve.values[i + 1]),
          reason: 'values[$i]=${curve.values[i]} < values[${i+1}]=${curve.values[i+1]}');
      }
    });

    test('hadNulls flag set when best window contains null', () {
      final readings = [
        _reading(0, power: 100),
        _reading(1, power: 800),
        _reading(2, power: null),
      ];
      final curve = MapCurveCalculator.computeBatch(readings, 'test');

      expect(curve.flags[0].hadNulls, false);   // 1s best=[800], no nulls
      expect(curve.flags[1].hadNulls, true);     // 2s best=[800,null]
    });

    test('wasEnforced flag set when monotonicity bumps value', () {
      final readings = [
        _reading(0, power: 100),
        _reading(1, power: 100),
        _reading(2, power: 800),
        _reading(3, power: null),
        _reading(4, power: null),
        _reading(5, power: 100),
      ];
      final curve = MapCurveCalculator.computeBatch(readings, 'test');

      // 4s window [800,null,null,100] → 2 non-null → 900/2 = 450
      // 3s window [100,100,800] → 333
      // 3s should be bumped to at least 4s value if 4s > 3s
      // Check that enforcement happened where needed
      for (int i = 0; i < 89; i++) {
        if (curve.flags[i].wasEnforced) {
          // Value should equal the next longer duration
          expect(curve.values[i], curve.values[i + 1]);
        }
      }
    });

    test('live and batch produce identical results', () {
      final readings = [
        _reading(0, power: 500),
        _reading(1, power: 1200),
        _reading(2, power: null),
        _reading(3, power: 900),
        _reading(4, power: 700),
      ];

      final batchCurve = MapCurveCalculator.computeBatch(readings, 'test');

      final liveCalc = MapCurveCalculator();
      MapCurve? liveCurve;
      for (final r in readings) {
        liveCurve = liveCalc.updateLive(r, 'test');
      }

      for (int i = 0; i < 90; i++) {
        expect(liveCurve!.values[i], closeTo(batchCurve.values[i], 0.001),
          reason: 'Mismatch at duration ${i + 1}s');
        expect(liveCurve.flags[i].hadNulls, batchCurve.flags[i].hadNulls);
        expect(liveCurve.flags[i].wasEnforced, batchCurve.flags[i].wasEnforced);
      }
    });
  });
}

// Helper to create readings concisely
SensorReading _reading(int offsetSeconds, {double? power}) {
  return SensorReading(
    timestamp: Duration(seconds: offsetSeconds),
    power: power,
  );
}
```

---

## IG11. Complete Vertical Slice — Effort Ends → MAP Computed → Cached to DB

This shows the exact sequence of operations when an effort ends during a live ride.

```dart
// In RideSessionManager, triggered when AutoLapDetector emits EffortEndedEvent:

void _handleEffortEnded(EffortEndedEvent event) {
  if (event.wasTooShort) {
    // Discard — don't create effort, notify UI briefly
    _notifyUI(EffortDiscarded(reason: 'Too short'));
    return;
  }

  // 1. Slice readings for this effort
  final effortReadings = _readingsBuffer
      .where((r) => r.timestamp.inSeconds >= event.startOffset
                  && r.timestamp.inSeconds <= event.endOffset)
      .toList();

  // 2. Compute EffortSummary
  final summary = SummaryCalculator.computeEffortSummary(effortReadings);

  // 3. Compute MapCurve (batch — replaces live curve)
  final effortId = Uuid().v4();
  final mapCurve = MapCurveCalculator.computeBatch(effortReadings, effortId);

  // 4. Build Effort object
  final effort = Effort(
    id: effortId,
    rideId: _currentRideId,
    effortNumber: _efforts.length + 1,
    startOffset: event.startOffset,
    endOffset: event.endOffset,
    type: event.isManual ? EffortType.manual : EffortType.auto,
    summary: EffortSummary(
      durationSeconds: summary.durationSeconds,
      avgPower: summary.avgPower,
      peakPower: summary.peakPower,
      avgHeartRate: summary.avgHeartRate,
      maxHeartRate: summary.maxHeartRate,
      avgCadence: summary.avgCadence,
      totalKilojoules: summary.totalKilojoules,
      avgLeftRightBalance: summary.avgLeftRightBalance,
      restSincePrevious: _efforts.isNotEmpty
          ? event.startOffset - _efforts.last.endOffset
          : null,
    ),
    mapCurve: mapCurve,
  );

  // 5. Add to in-memory list
  _efforts.add(effort);

  // 6. Dispose live effort calculator (its output is now replaced by batch)
  _liveEffortCalculator = null;

  // 7. Notify UI
  _notifyUI(EffortCompleted(effort: effort));
}

// Later, on ride end, everything is persisted in a single transaction:
Future<void> _persistRide() async {
  await _repository.saveRide(ride);              // 1. Ride row
  await _repository.insertReadings(              // 2. All readings
      ride.id, _readingsBuffer);
  await _repository.saveEfforts(                 // 3. All efforts
      ride.id, _efforts);
  for (final effort in _efforts) {               // 4. All MAP curves
    await _repository.saveMapCurve(
        effort.id, effort.mapCurve);
  }
  // Note: ride-level PDC is NOT persisted — computed on demand
  // Note: all of the above should be in a single DB transaction
}
```
