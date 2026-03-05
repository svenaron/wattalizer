# Wattalizer – Implementation Guide Additions

These sections extend the main Implementation Guide (IG1–IG11).

---

## IG12. Domain Model Classes — Complete Patterns

All domain models are immutable plain Dart classes. No code generation (no freezed, no json_serializable). Manual `copyWith` where needed. Factory constructors for DB mapping.

### IG12.1 SensorReading

```dart
class SensorReading {
  final Duration timestamp; // offset from ride start
  final double? power;
  final double? leftRightBalance;
  final double? leftPower;
  final double? rightPower;
  final int? heartRate;
  final double? cadence;
  final double? crankTorque;
  final int? accumulatedTorque;
  final int? crankRevolutions;
  final int? lastCrankEventTime;
  final int? maxForceMagnitude;
  final int? minForceMagnitude;
  final int? maxTorqueMagnitude;
  final int? minTorqueMagnitude;
  final int? topDeadSpotAngle;
  final int? bottomDeadSpotAngle;
  final int? accumulatedEnergy;
  final List<int>? rrIntervals;

  const SensorReading({
    required this.timestamp,
    this.power,
    this.leftRightBalance,
    this.leftPower,
    this.rightPower,
    this.heartRate,
    this.cadence,
    this.crankTorque,
    this.accumulatedTorque,
    this.crankRevolutions,
    this.lastCrankEventTime,
    this.maxForceMagnitude,
    this.minForceMagnitude,
    this.maxTorqueMagnitude,
    this.minTorqueMagnitude,
    this.topDeadSpotAngle,
    this.bottomDeadSpotAngle,
    this.accumulatedEnergy,
    this.rrIntervals,
  });

  /// From Drift row. offsetSeconds stored as int in DB.
  factory SensorReading.fromRow(ReadingRow row) {
    return SensorReading(
      timestamp: Duration(seconds: row.offsetSeconds),
      power: row.power,
      leftRightBalance: row.leftRightBalance,
      leftPower: row.leftPower,
      rightPower: row.rightPower,
      heartRate: row.heartRate,
      cadence: row.cadence,
      crankTorque: row.crankTorque,
      accumulatedTorque: row.accumulatedTorque,
      crankRevolutions: row.crankRevolutions,
      lastCrankEventTime: row.lastCrankEventTime,
      maxForceMagnitude: row.maxForceMagnitude,
      minForceMagnitude: row.minForceMagnitude,
      maxTorqueMagnitude: row.maxTorqueMagnitude,
      minTorqueMagnitude: row.minTorqueMagnitude,
      topDeadSpotAngle: row.topDeadSpotAngle,
      bottomDeadSpotAngle: row.bottomDeadSpotAngle,
      accumulatedEnergy: row.accumulatedEnergy,
      rrIntervals: row.rrIntervals != null
          ? (jsonDecode(row.rrIntervals!) as List).cast<int>()
          : null,
    );
  }

  /// To Drift companion for batch insert.
  ReadingsCompanion toCompanion(String rideId) {
    return ReadingsCompanion.insert(
      rideId: rideId,
      offsetSeconds: timestamp.inSeconds,
      power: Value.ofNullable(power),
      leftRightBalance: Value.ofNullable(leftRightBalance),
      leftPower: Value.ofNullable(leftPower),
      rightPower: Value.ofNullable(rightPower),
      heartRate: Value.ofNullable(heartRate),
      cadence: Value.ofNullable(cadence),
      crankTorque: Value.ofNullable(crankTorque),
      accumulatedTorque: Value.ofNullable(accumulatedTorque),
      crankRevolutions: Value.ofNullable(crankRevolutions),
      lastCrankEventTime: Value.ofNullable(lastCrankEventTime),
      maxForceMagnitude: Value.ofNullable(maxForceMagnitude),
      minForceMagnitude: Value.ofNullable(minForceMagnitude),
      maxTorqueMagnitude: Value.ofNullable(maxTorqueMagnitude),
      minTorqueMagnitude: Value.ofNullable(minTorqueMagnitude),
      topDeadSpotAngle: Value.ofNullable(topDeadSpotAngle),
      bottomDeadSpotAngle: Value.ofNullable(bottomDeadSpotAngle),
      accumulatedEnergy: Value.ofNullable(accumulatedEnergy),
      rrIntervals: Value.ofNullable(
        rrIntervals != null ? jsonEncode(rrIntervals) : null,
      ),
    );
  }
}
```

### IG12.2 Ride

```dart
enum RideSource { recorded, importedTcx }

class Ride {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> tags;
  final String? notes;
  final RideSource source;
  final String? autoLapConfigId;
  final List<Effort> efforts; // loaded eagerly on detail, empty on list
  final RideSummary summary;

  const Ride({
    required this.id,
    required this.startTime,
    this.endTime,
    this.tags = const [],
    this.notes,
    required this.source,
    this.autoLapConfigId,
    this.efforts = const [],
    required this.summary,
  });

  /// From Drift row + separately loaded efforts.
  /// Tags loaded via join or separate query.
  factory Ride.fromRow(RideRow row, List<String> tags, List<Effort> efforts) {
    return Ride(
      id: row.id,
      startTime: row.startTime,
      endTime: row.endTime,
      tags: tags,
      notes: row.notes,
      source: row.source == 'recorded'
          ? RideSource.recorded
          : RideSource.importedTcx,
      autoLapConfigId: row.autoLapConfigId,
      efforts: efforts,
      summary: RideSummary(
        durationSeconds: row.durationSeconds,
        activeDurationSeconds: row.activeDurationSeconds,
        avgPower: row.avgPower,
        maxPower: row.maxPower,
        avgHeartRate: row.avgHeartRate,
        maxHeartRate: row.maxHeartRate,
        avgCadence: row.avgCadence,
        totalKilojoules: row.totalKilojoules,
        avgLeftRightBalance: row.avgLeftRightBalance,
        readingCount: row.readingCount,
        effortCount: row.effortCount,
      ),
    );
  }

  RidesCompanion toCompanion() {
    return RidesCompanion.insert(
      id: id,
      startTime: startTime,
      endTime: Value.ofNullable(endTime),
      notes: Value.ofNullable(notes),
      source: source == RideSource.recorded ? 'recorded' : 'imported_tcx',
      autoLapConfigId: Value.ofNullable(autoLapConfigId),
      durationSeconds: summary.durationSeconds,
      activeDurationSeconds: summary.activeDurationSeconds,
      avgPower: summary.avgPower,
      maxPower: summary.maxPower,
      avgHeartRate: Value.ofNullable(summary.avgHeartRate),
      maxHeartRate: Value.ofNullable(summary.maxHeartRate),
      avgCadence: Value.ofNullable(summary.avgCadence),
      totalKilojoules: summary.totalKilojoules,
      avgLeftRightBalance: Value.ofNullable(summary.avgLeftRightBalance),
      readingCount: summary.readingCount,
      effortCount: summary.effortCount,
    );
  }

  Ride copyWith({
    List<String>? tags,
    String? notes,
    List<Effort>? efforts,
    RideSummary? summary,
    String? autoLapConfigId,
  }) {
    return Ride(
      id: id,
      startTime: startTime,
      endTime: endTime,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      source: source,
      autoLapConfigId: autoLapConfigId ?? this.autoLapConfigId,
      efforts: efforts ?? this.efforts,
      summary: summary ?? this.summary,
    );
  }
}
```

### IG12.3 Effort

```dart
enum EffortType { auto, manual }

class Effort {
  final String id;
  final String rideId;
  final int effortNumber;
  final int startOffset;
  final int endOffset;
  final EffortType type;
  final EffortSummary summary;
  final MapCurve mapCurve;

  const Effort({
    required this.id,
    required this.rideId,
    required this.effortNumber,
    required this.startOffset,
    required this.endOffset,
    required this.type,
    required this.summary,
    required this.mapCurve,
  });

  factory Effort.fromRow(EffortRow row, MapCurve curve) {
    return Effort(
      id: row.id,
      rideId: row.rideId,
      effortNumber: row.effortNumber,
      startOffset: row.startOffset,
      endOffset: row.endOffset,
      type: row.type == 'auto' ? EffortType.auto : EffortType.manual,
      summary: EffortSummary(
        durationSeconds: row.durationSeconds,
        avgPower: row.avgPower,
        peakPower: row.peakPower,
        avgHeartRate: row.avgHeartRate,
        maxHeartRate: row.maxHeartRate,
        avgCadence: row.avgCadence,
        totalKilojoules: row.totalKilojoules,
        avgLeftRightBalance: row.avgLeftRightBalance,
        restSincePrevious: row.restSincePrevious,
      ),
      mapCurve: curve,
    );
  }

  EffortsCompanion toCompanion() {
    return EffortsCompanion.insert(
      id: id,
      rideId: rideId,
      effortNumber: effortNumber,
      startOffset: startOffset,
      endOffset: endOffset,
      type: type == EffortType.auto ? 'auto' : 'manual',
      durationSeconds: summary.durationSeconds,
      avgPower: summary.avgPower,
      peakPower: summary.peakPower,
      avgHeartRate: Value.ofNullable(summary.avgHeartRate),
      maxHeartRate: Value.ofNullable(summary.maxHeartRate),
      avgCadence: Value.ofNullable(summary.avgCadence),
      totalKilojoules: summary.totalKilojoules,
      avgLeftRightBalance: Value.ofNullable(summary.avgLeftRightBalance),
      restSincePrevious: Value.ofNullable(summary.restSincePrevious),
    );
  }
}
```

### IG12.4 Summary Classes

```dart
class RideSummary {
  final int durationSeconds;
  final int activeDurationSeconds;
  final double avgPower;        // active efforts only
  final double maxPower;        // entire ride
  final int? avgHeartRate;      // active efforts only
  final int? maxHeartRate;      // entire ride
  final double? avgCadence;     // active efforts only
  final double totalKilojoules; // active efforts only
  final double? avgLeftRightBalance; // active efforts only
  final int readingCount;
  final int effortCount;

  const RideSummary({
    required this.durationSeconds,
    required this.activeDurationSeconds,
    required this.avgPower,
    required this.maxPower,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgCadence,
    required this.totalKilojoules,
    this.avgLeftRightBalance,
    required this.readingCount,
    required this.effortCount,
  });
}

class EffortSummary {
  final int durationSeconds;
  final double avgPower;
  final double peakPower; // highest single 1Hz reading
  final int? avgHeartRate;
  final int? maxHeartRate;
  final double? avgCadence;
  final double totalKilojoules;
  final double? avgLeftRightBalance;
  final int? restSincePrevious;

  const EffortSummary({
    required this.durationSeconds,
    required this.avgPower,
    required this.peakPower,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgCadence,
    required this.totalKilojoules,
    this.avgLeftRightBalance,
    this.restSincePrevious,
  });
}
```

### IG12.5 MapCurve and MapCurveFlags

```dart
class MapCurveFlags {
  final bool hadNulls;
  final bool wasEnforced;

  const MapCurveFlags({this.hadNulls = false, this.wasEnforced = false});
}

class MapCurve {
  final String entityId; // effort ID
  final List<double> values; // 90 entries, index 0 = 1s best
  final List<MapCurveFlags> flags; // 90 entries
  final DateTime computedAt;

  const MapCurve({
    required this.entityId,
    required this.values,
    required this.flags,
    required this.computedAt,
  });

  /// From 90 DB rows (one per duration).
  factory MapCurve.fromRows(String entityId, List<MapCurveRow> rows) {
    final values = List<double>.filled(90, 0.0);
    final flags = List<MapCurveFlags>.generate(90, (_) => MapCurveFlags());
    DateTime? latest;

    for (final row in rows) {
      final i = row.durationSeconds - 1; // duration 1 → index 0
      values[i] = row.bestAvgPower;
      flags[i] = MapCurveFlags(
        hadNulls: row.hadNulls,
        wasEnforced: row.wasEnforced,
      );
    }

    return MapCurve(
      entityId: entityId,
      values: values,
      flags: flags,
      computedAt: DateTime.now(),
    );
  }

  /// To 90 Drift companions for batch insert.
  List<MapCurvesCompanion> toCompanions() {
    return List.generate(90, (i) => MapCurvesCompanion.insert(
      effortId: entityId,
      durationSeconds: i + 1,
      bestAvgPower: values[i],
      hadNulls: Value(flags[i].hadNulls),
      wasEnforced: Value(flags[i].wasEnforced),
    ));
  }
}
```

### IG12.6 HistoricalRange and DurationRecord

```dart
enum HistorySpan { week, month, year, allTime }

class DurationRecord {
  final int durationSeconds;
  final double power;
  final String effortId;
  final String rideId;
  final DateTime rideDate;
  final int effortNumber;

  const DurationRecord({
    required this.durationSeconds,
    required this.power,
    required this.effortId,
    required this.rideId,
    required this.rideDate,
    required this.effortNumber,
  });
}

class HistoricalRange {
  final HistorySpan span;
  final List<DurationRecord> best;  // 90 entries, best[0] = 1s best (= PDC)
  final List<DurationRecord> worst; // 90 entries
  final int effortCount;

  const HistoricalRange({
    required this.span,
    required this.best,
    required this.worst,
    required this.effortCount,
  });
}
```

### IG12.7 AutoLapConfig

```dart
class AutoLapConfig {
  final String id;
  final String name;
  final double startDeltaWatts;
  final int startConfirmSeconds;
  final int startDropoutTolerance;
  final double endDeltaWatts;
  final int endConfirmSeconds;
  final int minEffortSeconds;
  final int preEffortBaselineWindow;
  final int inEffortTrailingWindow;
  final bool isDefault;

  const AutoLapConfig({
    required this.id,
    required this.name,
    required this.startDeltaWatts,
    this.startConfirmSeconds = 2,
    this.startDropoutTolerance = 1,
    required this.endDeltaWatts,
    this.endConfirmSeconds = 5,
    this.minEffortSeconds = 3,
    this.preEffortBaselineWindow = 15,
    this.inEffortTrailingWindow = 10,
    this.isDefault = false,
  });

  // --- Presets (from spec §6.5) ---

  static AutoLapConfig shortSprint({String? id}) => AutoLapConfig(
    id: id ?? 'preset_short_sprint',
    name: 'Short Sprint',
    startDeltaWatts: 200,
    startConfirmSeconds: 1,
    startDropoutTolerance: 1,
    endDeltaWatts: 150,
    endConfirmSeconds: 4,
    minEffortSeconds: 2,
    preEffortBaselineWindow: 10,
    inEffortTrailingWindow: 5,
  );

  static AutoLapConfig flying200({String? id}) => AutoLapConfig(
    id: id ?? 'preset_flying_200',
    name: 'Flying 200m',
    startDeltaWatts: 150,
    startConfirmSeconds: 2,
    startDropoutTolerance: 1,
    endDeltaWatts: 120,
    endConfirmSeconds: 5,
    minEffortSeconds: 5,
    preEffortBaselineWindow: 15,
    inEffortTrailingWindow: 8,
  );

  static AutoLapConfig teamSprint({String? id}) => AutoLapConfig(
    id: id ?? 'preset_team_sprint',
    name: 'Team Sprint',
    startDeltaWatts: 120,
    startConfirmSeconds: 3,
    startDropoutTolerance: 1,
    endDeltaWatts: 100,
    endConfirmSeconds: 6,
    minEffortSeconds: 10,
    preEffortBaselineWindow: 20,
    inEffortTrailingWindow: 15,
  );

  AutolapConfigsCompanion toCompanion() {
    return AutolapConfigsCompanion.insert(
      id: id,
      name: name,
      startDeltaWatts: startDeltaWatts,
      startConfirmSeconds: Value(startConfirmSeconds),
      startDropoutTolerance: Value(startDropoutTolerance),
      endDeltaWatts: endDeltaWatts,
      endConfirmSeconds: Value(endConfirmSeconds),
      minEffortSeconds: Value(minEffortSeconds),
      preEffortBaselineWindow: Value(preEffortBaselineWindow),
      inEffortTrailingWindow: Value(inEffortTrailingWindow),
      isDefault: isDefault,
    );
  }
}
```

### IG12.8 DeviceInfo

```dart
enum SensorType { power, heartRate, cadence }

class DeviceInfo {
  final String deviceId;
  final String displayName;
  final Set<SensorType> supportedServices;
  final DateTime lastConnected;
  final bool autoConnect;

  const DeviceInfo({
    required this.deviceId,
    required this.displayName,
    required this.supportedServices,
    required this.lastConnected,
    this.autoConnect = true,
  });

  DeviceInfo copyWith({String? displayName, bool? autoConnect}) {
    return DeviceInfo(
      deviceId: deviceId,
      displayName: displayName ?? this.displayName,
      supportedServices: supportedServices,
      lastConnected: lastConnected,
      autoConnect: autoConnect ?? this.autoConnect,
    );
  }
}
```

---

## IG13. SummaryCalculator — Complete Implementation

```dart
class SummaryCalculator {
  /// Compute EffortSummary from a slice of readings within effort boundaries.
  /// All readings in the slice are treated as active (within an effort).
  static EffortSummary computeEffortSummary(List<SensorReading> readings) {
    if (readings.isEmpty) {
      return const EffortSummary(
        durationSeconds: 0,
        avgPower: 0,
        peakPower: 0,
        totalKilojoules: 0,
      );
    }

    double powerSum = 0;
    int powerCount = 0;
    double peakPower = 0;
    int hrSum = 0;
    int hrCount = 0;
    int maxHr = 0;
    double cadSum = 0;
    int cadCount = 0;
    double lrSum = 0;
    int lrCount = 0;

    for (final r in readings) {
      if (r.power != null) {
        powerSum += r.power!;
        powerCount++;
        if (r.power! > peakPower) peakPower = r.power!;
      }
      if (r.heartRate != null) {
        hrSum += r.heartRate!;
        hrCount++;
        if (r.heartRate! > maxHr) maxHr = r.heartRate!;
      }
      if (r.cadence != null) {
        cadSum += r.cadence!;
        cadCount++;
      }
      if (r.leftRightBalance != null) {
        lrSum += r.leftRightBalance!;
        lrCount++;
      }
    }

    final duration = readings.last.timestamp.inSeconds -
        readings.first.timestamp.inSeconds + 1;
    final avgPower = powerCount > 0 ? powerSum / powerCount : 0.0;

    return EffortSummary(
      durationSeconds: duration,
      avgPower: avgPower,
      peakPower: peakPower,
      avgHeartRate: hrCount > 0 ? (hrSum / hrCount).round() : null,
      maxHeartRate: hrCount > 0 ? maxHr : null,
      avgCadence: cadCount > 0 ? cadSum / cadCount : null,
      totalKilojoules: avgPower * duration / 1000.0,
      avgLeftRightBalance: lrCount > 0 ? lrSum / lrCount : null,
    );
  }

  /// Compute RideSummary from the full ride readings and the detected efforts.
  ///
  /// CRITICAL DISTINCTION:
  /// - avgPower, avgHeartRate, avgCadence, avgLeftRightBalance, totalKilojoules,
  ///   activeDurationSeconds → computed from ACTIVE EFFORT READINGS ONLY
  /// - maxPower, maxHeartRate → computed from ENTIRE RIDE (all readings)
  /// - durationSeconds, readingCount → computed from ENTIRE RIDE
  static RideSummary computeRideSummary(
    List<SensorReading> allReadings,
    List<Effort> efforts,
  ) {
    if (allReadings.isEmpty) {
      return RideSummary(
        durationSeconds: 0,
        activeDurationSeconds: 0,
        avgPower: 0,
        maxPower: 0,
        totalKilojoules: 0,
        readingCount: 0,
        effortCount: efforts.length,
      );
    }

    // --- Entire ride: max values ---
    double maxPower = 0;
    int maxHr = 0;
    for (final r in allReadings) {
      if (r.power != null && r.power! > maxPower) maxPower = r.power!;
      if (r.heartRate != null && r.heartRate! > maxHr) maxHr = r.heartRate!;
    }

    // --- Active effort readings only: averages ---
    // Build a set of active offsets for efficient lookup
    final activeOffsets = <int>{};
    for (final e in efforts) {
      for (int t = e.startOffset; t <= e.endOffset; t++) {
        activeOffsets.add(t);
      }
    }

    double powerSum = 0;
    int powerCount = 0;
    int hrSum = 0;
    int hrCount = 0;
    double cadSum = 0;
    int cadCount = 0;
    double lrSum = 0;
    int lrCount = 0;

    for (final r in allReadings) {
      if (!activeOffsets.contains(r.timestamp.inSeconds)) continue;

      if (r.power != null) {
        powerSum += r.power!;
        powerCount++;
      }
      if (r.heartRate != null) {
        hrSum += r.heartRate!;
        hrCount++;
      }
      if (r.cadence != null) {
        cadSum += r.cadence!;
        cadCount++;
      }
      if (r.leftRightBalance != null) {
        lrSum += r.leftRightBalance!;
        lrCount++;
      }
    }

    final totalDuration = allReadings.last.timestamp.inSeconds -
        allReadings.first.timestamp.inSeconds + 1;
    final activeDuration = activeOffsets.length;
    final avgPower = powerCount > 0 ? powerSum / powerCount : 0.0;

    return RideSummary(
      durationSeconds: totalDuration,
      activeDurationSeconds: activeDuration,
      avgPower: avgPower,
      maxPower: maxPower,
      avgHeartRate: hrCount > 0 ? (hrSum / hrCount).round() : null,
      maxHeartRate: maxHr > 0 ? maxHr : null,
      avgCadence: cadCount > 0 ? cadSum / cadCount : null,
      totalKilojoules: avgPower * activeDuration / 1000.0,
      avgLeftRightBalance: lrCount > 0 ? lrSum / lrCount : null,
      readingCount: allReadings.length,
      effortCount: efforts.length,
    );
  }
}
```

### IG13.1 Worked Example

**Ride readings (10 seconds):**
```
t=0: power=100, hr=140  (recovery)
t=1: power=120, hr=142  (recovery)
t=2: power=800, hr=155  (effort 1 start)
t=3: power=900, hr=165
t=4: power=850, hr=170
t=5: power=750, hr=172  (effort 1 end)
t=6: power=150, hr=168  (recovery)
t=7: power=130, hr=160  (recovery)
t=8: power=null, hr=155 (dropout)
t=9: power=110, hr=150  (recovery)
```

**Effort 1:** startOffset=2, endOffset=5

**EffortSummary for effort 1:**
- readings slice: t=2..5 → [800, 900, 850, 750]
- durationSeconds: 5 - 2 + 1 = 4
- avgPower: (800+900+850+750)/4 = 825.0
- peakPower: 900.0
- avgHeartRate: (155+165+170+172)/4 = 165.5 → 166
- maxHeartRate: 172
- totalKilojoules: 825.0 × 4 / 1000 = 3.3

**RideSummary:**
- durationSeconds: 9 - 0 + 1 = 10
- activeDurationSeconds: 4 (offsets 2,3,4,5)
- avgPower: 825.0 (from active readings only, same as effort since 1 effort)
- maxPower: 900.0 (entire ride — happens to be in effort)
- avgHeartRate: 166 (active only)
- maxHeartRate: 172 (entire ride)
- totalKilojoules: 825.0 × 4 / 1000 = 3.3
- readingCount: 10
- effortCount: 1

**Note:** t=0,1,6,7,8,9 are recovery — excluded from avgPower, avgHeartRate, etc. but maxPower/maxHeartRate scan the entire ride.

---

## IG14. Provider Wiring Patterns

### IG14.1 keepAlive Provider (rideSessionProvider)

```dart
/// Ride session state — sealed class for exhaustive matching.
sealed class RideState {}

class RideStateIdle extends RideState {
  final Ride? lastRide; // populated after ride end, null on app start
  RideStateIdle({this.lastRide});
}

class RideStateActive extends RideState {
  final String rideId;
  final DateTime startTime;
  final List<SensorReading> readings;
  final List<Effort> completedEfforts;
  final AutoLapState autoLapState;
  final double currentBaseline;
  final MapCurve? liveEffortCurve; // null between efforts
  final int? activeEffortStartOffset;
  RideStateActive({
    required this.rideId,
    required this.startTime,
    required this.readings,
    required this.completedEfforts,
    required this.autoLapState,
    required this.currentBaseline,
    this.liveEffortCurve,
    this.activeEffortStartOffset,
  });
}

class RideStateError extends RideState {
  final String message;
  RideStateError(this.message);
}

/// The main orchestration provider. keepAlive — survives navigation.
final rideSessionProvider =
    NotifierProvider<RideSessionNotifier, RideState>(RideSessionNotifier.new);

class RideSessionNotifier extends Notifier<RideState> {
  late final RideRepository _repo;
  late final BleService _ble;
  
  RideSessionManager? _manager; // null when idle

  @override
  RideState build() {
    _repo = ref.read(rideRepositoryProvider);
    _ble = ref.read(bleServiceProvider);
    return RideStateIdle();
  }

  Future<void> startRide() async {
    final config = await ref.read(autoLapConfigProvider.future);
    _manager = RideSessionManager(
      repository: _repo,
      config: config,
      onStateChanged: (s) => state = s,
    );
    _manager!.start(ref.read(sensorStreamProvider));
  }

  void manualLap() => _manager?.manualLap();

  Future<void> endRide() async {
    try {
      final ride = await _manager?.end();
      _manager = null;
      state = RideStateIdle(lastRide: ride);
      // Invalidate downstream providers that depend on ride data
      ref.invalidate(historicalRangeProvider);
      ref.invalidate(maxPowerProvider);
    } on AppError catch (e) {
      state = RideStateError('Failed to save ride: $e');
    }
  }
}
```

### IG14.2 Derived Provider (activeEffortProvider)

```dart
/// Extracts just the active effort state from the ride session.
/// Avoids rebuilding everything when only effort state changes.
final activeEffortProvider = Provider<ActiveEffortState>((ref) {
  final rideState = ref.watch(rideSessionProvider);
  return switch (rideState) {
    RideStateActive(
      :final autoLapState,
      :final liveEffortCurve,
      :final activeEffortStartOffset,
      :final currentBaseline,
    ) =>
      ActiveEffortState(
        phase: autoLapState,
        liveCurve: liveEffortCurve,
        startOffset: activeEffortStartOffset,
        baseline: currentBaseline,
      ),
    _ => const ActiveEffortState.idle(),
  };
});

class ActiveEffortState {
  final AutoLapState phase;
  final MapCurve? liveCurve;
  final int? startOffset;
  final double baseline;

  const ActiveEffortState({
    required this.phase,
    this.liveCurve,
    this.startOffset,
    this.baseline = 0,
  });

  const ActiveEffortState.idle()
      : phase = AutoLapState.idle,
        liveCurve = null,
        startOffset = null,
        baseline = 0;
}
```

### IG14.3 autoDispose with Dependencies (historicalRangeProvider)

```dart
/// Computes best/worst envelopes for the selected span and tag filter.
/// autoDispose — only alive while a screen needs it.
/// Invalidated when a new ride is saved (from rideSessionProvider).
final historicalRangeProvider =
    FutureProvider.autoDispose<HistoricalRange?>((ref) async {
  final span = ref.watch(spanSelectionProvider);
  final tags = ref.watch(tagFilterProvider);
  final repo = ref.read(rideRepositoryProvider);
  final calc = HistoricalRangeCalculator();

  // Determine date range from span
  final now = DateTime.now();
  final DateTime? from = switch (span) {
    HistorySpan.week => now.subtract(const Duration(days: 7)),
    HistorySpan.month => DateTime(now.year, now.month - 1, now.day),
    HistorySpan.year => DateTime(now.year - 1, now.month, now.day),
    HistorySpan.allTime => null,
  };

  final curves = await repo.getAllEffortCurves(
    from: from,
    to: now,
    tags: tags.isEmpty ? null : tags,
  );

  if (curves.isEmpty) return null;

  return calc.compute(curves);
});

/// Single source of truth for selected history span.
final spanSelectionProvider = StateProvider<HistorySpan>((ref) {
  return HistorySpan.allTime;
});

/// Selected tag filters (empty = show all).
final tagFilterProvider = StateProvider<Set<String>>((ref) {
  return {};
});
```

### IG14.4 maxPowerProvider

```dart
/// Max power for Focus Mode background color scaling.
/// Manual override from settings, or auto-derived from all-time 1s best.
final maxPowerProvider = FutureProvider.keepAlive<double>((ref) async {
  final repo = ref.read(rideRepositoryProvider);

  // Check for manual override
  final settings = await repo.getAppSetting('maxPower');
  if (settings != null) {
    return double.parse(settings);
  }

  // Auto-derive from all-time best 1s
  // Use historicalRangeProvider with allTime span, no tag filter
  final curves = await repo.getAllEffortCurves();
  if (curves.isEmpty) return 1500.0; // sensible default for first use

  final calc = HistoricalRangeCalculator();
  final range = calc.compute(curves);
  return range.best[0].power; // 1s best = index 0
});
```

---

## IG15. BLE Parser Byte-Level Examples

### IG15.1 Power Parser (Cycling Power Measurement, 0x2A63)

```dart
class PowerData {
  final int instantaneousPower; // Watts, signed 16-bit
  final double? pedalBalance;   // left leg %, 0-100
  final int? accumulatedTorque; // raw value (1/32 Nm resolution)
  final int? crankRevolutions;  // cumulative
  final int? lastCrankEventTime; // 1/1024 seconds
  final int? maxForceMagnitude;  // Newtons
  final int? minForceMagnitude;
  final int? maxTorqueMagnitude; // Nm × 32
  final int? minTorqueMagnitude;
  final int? topDeadSpotAngle;   // degrees
  final int? bottomDeadSpotAngle;
  final int? accumulatedEnergy;  // kJ

  const PowerData({
    required this.instantaneousPower,
    this.pedalBalance,
    this.accumulatedTorque,
    this.crankRevolutions,
    this.lastCrankEventTime,
    this.maxForceMagnitude,
    this.minForceMagnitude,
    this.maxTorqueMagnitude,
    this.minTorqueMagnitude,
    this.topDeadSpotAngle,
    this.bottomDeadSpotAngle,
    this.accumulatedEnergy,
  });
}

class PowerParser {
  /// Parse Cycling Power Measurement (0x2A63) characteristic value.
  /// Returns null if data is too short (minimum 4 bytes: 2 flags + 2 power).
  static PowerData? parse(List<int> bytes) {
    if (bytes.length < 4) return null;

    // Flags: 16-bit little-endian at offset 0
    final flags = bytes[0] | (bytes[1] << 8);
    int offset = 2;

    // Instantaneous Power: signed 16-bit LE, always present
    final power = _readS16(bytes, offset);
    offset += 2;

    // Bit 0: Pedal Power Balance present
    double? balance;
    if (flags & 0x0001 != 0) {
      if (offset >= bytes.length) return PowerData(instantaneousPower: power);
      balance = bytes[offset] / 2.0; // 0.5% resolution
      offset += 1;
    }

    // Bit 1: Pedal Power Balance Reference (no data, just a flag)
    // (indicates whether balance is left or unknown — we always treat as left %)

    // Bit 2: Accumulated Torque present
    int? accTorque;
    if (flags & 0x0004 != 0) {
      if (offset + 1 >= bytes.length) {
        return PowerData(instantaneousPower: power, pedalBalance: balance);
      }
      accTorque = _readU16(bytes, offset);
      offset += 2;
    }

    // Bit 3: Accumulated Torque Source (no data, just a flag)

    // Bit 4: Wheel Revolution Data present (u32 revs + u16 event time)
    if (flags & 0x0010 != 0) {
      offset += 6; // skip — not used, but must advance offset
    }

    // Bit 5: Crank Revolution Data present
    int? crankRevs;
    int? crankTime;
    if (flags & 0x0020 != 0) {
      if (offset + 3 >= bytes.length) {
        return PowerData(
          instantaneousPower: power,
          pedalBalance: balance,
          accumulatedTorque: accTorque,
        );
      }
      crankRevs = _readU16(bytes, offset);
      offset += 2;
      crankTime = _readU16(bytes, offset);
      offset += 2;
    }

    // Bit 6: Extreme Force Magnitudes present
    int? maxForce, minForce;
    if (flags & 0x0040 != 0) {
      if (offset + 3 >= bytes.length) {
        return PowerData(
          instantaneousPower: power,
          pedalBalance: balance,
          accumulatedTorque: accTorque,
          crankRevolutions: crankRevs,
          lastCrankEventTime: crankTime,
        );
      }
      maxForce = _readS16(bytes, offset);
      offset += 2;
      minForce = _readS16(bytes, offset);
      offset += 2;
    }

    // Bit 7: Extreme Torque Magnitudes present
    int? maxTorque, minTorque;
    if (flags & 0x0080 != 0) {
      if (offset + 3 >= bytes.length) {
        return PowerData(
          instantaneousPower: power,
          pedalBalance: balance,
          accumulatedTorque: accTorque,
          crankRevolutions: crankRevs,
          lastCrankEventTime: crankTime,
          maxForceMagnitude: maxForce,
          minForceMagnitude: minForce,
        );
      }
      maxTorque = _readS16(bytes, offset);
      offset += 2;
      minTorque = _readS16(bytes, offset);
      offset += 2;
    }

    // Bit 8: Extreme Angles present (3 bytes packed: 12-bit + 12-bit)
    // Skip for v1 — stored as topDeadSpotAngle/bottomDeadSpotAngle instead
    if (flags & 0x0100 != 0) {
      offset += 3;
    }

    // Bit 9: Top Dead Spot Angle present
    int? topAngle;
    if (flags & 0x0200 != 0) {
      if (offset + 1 >= bytes.length) {
        return _buildPartial(power, balance, accTorque, crankRevs,
            crankTime, maxForce, minForce, maxTorque, minTorque);
      }
      topAngle = _readU16(bytes, offset);
      offset += 2;
    }

    // Bit 10: Bottom Dead Spot Angle present
    int? bottomAngle;
    if (flags & 0x0400 != 0) {
      if (offset + 1 >= bytes.length) {
        return _buildPartial(power, balance, accTorque, crankRevs,
            crankTime, maxForce, minForce, maxTorque, minTorque,
            topAngle: topAngle);
      }
      bottomAngle = _readU16(bytes, offset);
      offset += 2;
    }

    // Bit 11: Accumulated Energy present
    int? energy;
    if (flags & 0x0800 != 0) {
      if (offset + 1 >= bytes.length) {
        return _buildPartial(power, balance, accTorque, crankRevs,
            crankTime, maxForce, minForce, maxTorque, minTorque,
            topAngle: topAngle, bottomAngle: bottomAngle);
      }
      energy = _readU16(bytes, offset);
      offset += 2;
    }

    return PowerData(
      instantaneousPower: power,
      pedalBalance: balance,
      accumulatedTorque: accTorque,
      crankRevolutions: crankRevs,
      lastCrankEventTime: crankTime,
      maxForceMagnitude: maxForce,
      minForceMagnitude: minForce,
      maxTorqueMagnitude: maxTorque,
      minTorqueMagnitude: minTorque,
      topDeadSpotAngle: topAngle,
      bottomDeadSpotAngle: bottomAngle,
      accumulatedEnergy: energy,
    );
  }

  static int _readU16(List<int> b, int o) => b[o] | (b[o + 1] << 8);
  static int _readS16(List<int> b, int o) {
    final v = b[o] | (b[o + 1] << 8);
    return v >= 0x8000 ? v - 0x10000 : v;
  }

  // Helper to build partial result when buffer is truncated
  static PowerData _buildPartial(
    int power, double? balance, int? accTorque,
    int? crankRevs, int? crankTime,
    int? maxForce, int? minForce,
    int? maxTorque, int? minTorque, {
    int? topAngle, int? bottomAngle,
  }) {
    return PowerData(
      instantaneousPower: power,
      pedalBalance: balance,
      accumulatedTorque: accTorque,
      crankRevolutions: crankRevs,
      lastCrankEventTime: crankTime,
      maxForceMagnitude: maxForce,
      minForceMagnitude: minForce,
      maxTorqueMagnitude: maxTorque,
      minTorqueMagnitude: minTorque,
      topDeadSpotAngle: topAngle,
      bottomDeadSpotAngle: bottomAngle,
    );
  }
}
```

### IG15.2 Test Fixtures with Byte Arrays

```dart
void main() {
  group('PowerParser', () {
    test('minimal: power only, no optional fields', () {
      // Flags: 0x0000 (no optional fields)
      // Power: 350W (0x015E little-endian)
      final bytes = [0x00, 0x00, 0x5E, 0x01];
      final data = PowerParser.parse(bytes);

      expect(data, isNotNull);
      expect(data!.instantaneousPower, 350);
      expect(data.pedalBalance, isNull);
      expect(data.crankRevolutions, isNull);
    });

    test('power + pedal balance', () {
      // Flags: 0x0001 (bit 0 set = balance present)
      // Power: 420W (0x01A4)
      // Balance: 104 → 52.0% left
      final bytes = [0x01, 0x00, 0xA4, 0x01, 0x68];
      final data = PowerParser.parse(bytes);

      expect(data!.instantaneousPower, 420);
      expect(data.pedalBalance, 52.0);
    });

    test('power + balance + crank revolution data', () {
      // Flags: 0x0021 (bit 0 + bit 5)
      // Power: 800W (0x0320)
      // Balance: 98 → 49.0%
      // Crank revolutions: 1234 (0x04D2)
      // Last crank event: 5678 (0x162E) → 5678/1024 = 5.545s
      final bytes = [
        0x21, 0x00,       // flags
        0x20, 0x03,       // power 800
        0x62,             // balance 49.0%
        0xD2, 0x04,       // crank revs 1234
        0x2E, 0x16,       // crank event time 5678
      ];
      final data = PowerParser.parse(bytes);

      expect(data!.instantaneousPower, 800);
      expect(data.pedalBalance, 49.0);
      expect(data.crankRevolutions, 1234);
      expect(data.lastCrankEventTime, 5678);
    });

    test('negative power (braking/error)', () {
      // Flags: 0x0000
      // Power: -10 (0xFFF6 as unsigned = 65526, signed = -10)
      final bytes = [0x00, 0x00, 0xF6, 0xFF];
      final data = PowerParser.parse(bytes);

      expect(data!.instantaneousPower, -10);
    });

    test('zero power (coasting)', () {
      final bytes = [0x00, 0x00, 0x00, 0x00];
      final data = PowerParser.parse(bytes);

      expect(data!.instantaneousPower, 0);
    });

    test('too short (< 4 bytes) returns null', () {
      expect(PowerParser.parse([0x00, 0x00, 0x5E]), isNull);
      expect(PowerParser.parse([]), isNull);
    });

    test('all optional fields present', () {
      // Flags: 0x0FE5 = bits 0,2,5,6,7,8,9,10,11
      //   bit 0: balance, bit 2: acc torque, bit 5: crank
      //   bit 6: extreme force, bit 7: extreme torque
      //   bit 8: extreme angles, bit 9: top dead spot
      //   bit 10: bottom dead spot, bit 11: acc energy
      final bytes = [
        0xE5, 0x0F,       // flags
        0xE8, 0x03,       // power: 1000W
        0x64,             // balance: 50.0%
        0x10, 0x27,       // acc torque: 10000
        // (bit 3,4 not set — no wheel data)
        0xD2, 0x04,       // crank revs: 1234
        0x00, 0x04,       // crank time: 1024
        0xF4, 0x01,       // max force: 500N
        0x96, 0x00,       // min force: 150N
        0xC8, 0x00,       // max torque: 200
        0x64, 0x00,       // min torque: 100
        0x00, 0x5A, 0xB4, // extreme angles (3 bytes packed, skipped)
        0x0A, 0x00,       // top dead spot: 10°
        0xB4, 0x00,       // bottom dead spot: 180°
        0x05, 0x00,       // acc energy: 5 kJ
      ];
      final data = PowerParser.parse(bytes);

      expect(data!.instantaneousPower, 1000);
      expect(data.pedalBalance, 50.0);
      expect(data.accumulatedTorque, 10000);
      expect(data.crankRevolutions, 1234);
      expect(data.lastCrankEventTime, 1024);
      expect(data.maxForceMagnitude, 500);
      expect(data.minForceMagnitude, 150);
      expect(data.maxTorqueMagnitude, 200);
      expect(data.minTorqueMagnitude, 100);
      expect(data.topDeadSpotAngle, 10);
      expect(data.bottomDeadSpotAngle, 180);
      expect(data.accumulatedEnergy, 5);
    });
  });
}
```

### IG15.3 HR Parser

```dart
class HeartRateData {
  final int heartRate; // BPM
  final List<int>? rrIntervals; // milliseconds

  const HeartRateData({required this.heartRate, this.rrIntervals});
}

class HrParser {
  static HeartRateData? parse(List<int> bytes) {
    if (bytes.length < 2) return null;

    final flags = bytes[0];
    int offset = 1;

    // Bit 0: HR format. 0 = uint8, 1 = uint16
    int hr;
    if (flags & 0x01 != 0) {
      if (offset + 1 >= bytes.length) return null;
      hr = bytes[offset] | (bytes[offset + 1] << 8);
      offset += 2;
    } else {
      hr = bytes[offset];
      offset += 1;
    }

    // Bit 1: Sensor Contact Status (skip)
    // Bit 2: Sensor Contact Supported (skip)

    // Bit 3: Energy Expended present
    if (flags & 0x08 != 0) {
      offset += 2; // skip u16 energy
    }

    // Bit 4: RR-Interval present
    List<int>? rr;
    if (flags & 0x10 != 0) {
      rr = [];
      while (offset + 1 < bytes.length) {
        final raw = bytes[offset] | (bytes[offset + 1] << 8);
        // Convert from 1/1024 seconds to milliseconds
        rr.add((raw * 1000 / 1024).round());
        offset += 2;
      }
    }

    return HeartRateData(heartRate: hr, rrIntervals: rr);
  }
}
```

**Test fixtures:**
```dart
test('8-bit HR, no RR', () {
  // Flags: 0x00 (8-bit HR, no extras)
  // HR: 165
  final data = HrParser.parse([0x00, 0xA5]);
  expect(data!.heartRate, 165);
  expect(data.rrIntervals, isNull);
});

test('16-bit HR with RR intervals', () {
  // Flags: 0x11 (16-bit HR + RR present)
  // HR: 172 (0x00AC)
  // RR: 710ms → 727 in 1/1024s (0x02D7)
  // RR: 690ms → 707 in 1/1024s (0x02C3)
  final data = HrParser.parse([0x11, 0xAC, 0x00, 0xD7, 0x02, 0xC3, 0x02]);
  expect(data!.heartRate, 172);
  expect(data.rrIntervals, hasLength(2));
  expect(data.rrIntervals![0], closeTo(710, 2)); // rounding tolerance
  expect(data.rrIntervals![1], closeTo(690, 2));
});
```

### IG15.4 CSC Parser (Stateful)

```dart
class CadenceData {
  final double rpm;

  const CadenceData({required this.rpm});
}

class CscParser {
  int? _prevRevs;
  int? _prevTime;

  /// Parse CSC Measurement (0x2A5B). Returns null on first call
  /// or when delta cannot be computed.
  CadenceData? parse(List<int> bytes) {
    if (bytes.length < 1) return null;

    final flags = bytes[0];
    int offset = 1;

    // Bit 0: Wheel Revolution Data present (skip)
    if (flags & 0x01 != 0) {
      offset += 6; // u32 wheel revs + u16 wheel event time
    }

    // Bit 1: Crank Revolution Data present
    if (flags & 0x02 == 0) return null; // no crank data
    if (offset + 3 >= bytes.length) return null;

    final revs = bytes[offset] | (bytes[offset + 1] << 8);
    offset += 2;
    final time = bytes[offset] | (bytes[offset + 1] << 8);
    offset += 2;

    if (_prevRevs == null || _prevTime == null) {
      _prevRevs = revs;
      _prevTime = time;
      return null; // first reading, no delta
    }

    // Handle 16-bit rollover
    int deltaRevs = (revs - _prevRevs!) & 0xFFFF;
    int deltaTime = (time - _prevTime!) & 0xFFFF;

    _prevRevs = revs;
    _prevTime = time;

    if (deltaTime == 0) return null; // avoid div by zero

    // deltaTime is in 1/1024 seconds
    final rpm = (deltaRevs / (deltaTime / 1024.0)) * 60.0;

    // Sanity check: cadence > 250 RPM is likely a glitch
    if (rpm > 250) return null;

    return CadenceData(rpm: rpm);
  }

  /// Call on reconnection to avoid bogus delta from stale previous values.
  void reset() {
    _prevRevs = null;
    _prevTime = null;
  }
}
```

**Test fixtures:**
```dart
test('two readings produce cadence', () {
  final parser = CscParser();

  // First reading: 100 revs at time 10240 (10s in 1/1024)
  // Flags: 0x02 (crank data present, no wheel)
  final first = parser.parse([0x02, 0x64, 0x00, 0x00, 0x28]);
  expect(first, isNull); // first reading → null

  // Second reading: 102 revs at time 12288 (12s in 1/1024)
  // Delta: 2 revs / 2s = 1 rev/s = 60 RPM
  final second = parser.parse([0x02, 0x66, 0x00, 0x00, 0x30]);
  expect(second, isNotNull);
  expect(second!.rpm, closeTo(60.0, 0.1));
});

test('16-bit rollover handled', () {
  final parser = CscParser();

  // First: revs=65534, time=65000
  parser.parse([0x02, 0xFE, 0xFF, 0xE8, 0xFD]);

  // Second: revs=1 (rolled over), time=1048 (rolled over)
  // Delta revs: (1 - 65534) & 0xFFFF = 3
  // Delta time: (1048 - 65000) & 0xFFFF = 1584 → 1584/1024 = 1.547s
  // RPM: (3 / 1.547) * 60 = 116.4
  final result = parser.parse([0x02, 0x01, 0x00, 0x18, 0x04]);
  expect(result, isNotNull);
  expect(result!.rpm, closeTo(116.4, 0.5));
});

test('reset clears state', () {
  final parser = CscParser();
  parser.parse([0x02, 0x64, 0x00, 0x00, 0x28]);
  parser.reset();
  // After reset, next reading is treated as first → null
  final result = parser.parse([0x02, 0x66, 0x00, 0x00, 0x30]);
  expect(result, isNull);
});
```

---

## IG16. Readings Table in Drift

The largest table with the most nullable columns. Shown explicitly because of the JSON-encoded `rrIntervals` field.

```dart
class Readings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rideId => text().references(Rides, #id)();
  IntColumn get offsetSeconds => integer()();
  RealColumn get power => real().nullable()();
  RealColumn get leftRightBalance => real().nullable()();
  RealColumn get leftPower => real().nullable()();
  RealColumn get rightPower => real().nullable()();
  IntColumn get heartRate => integer().nullable()();
  RealColumn get cadence => real().nullable()();
  RealColumn get crankTorque => real().nullable()();
  IntColumn get accumulatedTorque => integer().nullable()();
  IntColumn get crankRevolutions => integer().nullable()();
  IntColumn get lastCrankEventTime => integer().nullable()();
  IntColumn get maxForceMagnitude => integer().nullable()();
  IntColumn get minForceMagnitude => integer().nullable()();
  IntColumn get maxTorqueMagnitude => integer().nullable()();
  IntColumn get minTorqueMagnitude => integer().nullable()();
  IntColumn get topDeadSpotAngle => integer().nullable()();
  IntColumn get bottomDeadSpotAngle => integer().nullable()();
  IntColumn get accumulatedEnergy => integer().nullable()();
  TextColumn get rrIntervals => text().nullable()(); // JSON: "[710, 690]"

  // Composite index for efficient range queries
  // Drift generates this as CREATE INDEX idx_readings_ride_offset
  //   ON readings (ride_id, offset_seconds)
}
```

### IG16.1 Batch Insert Pattern

Readings are batch-inserted in a single transaction on ride end. This is critical for performance — 3600+ rows for a 1-hour ride.

```dart
// In LocalRideRepository

@override
Future<void> insertReadings(
    String rideId, List<SensorReading> readings) async {
  await _db.transaction(() async {
    // Drift's batch API for efficient multi-row insert
    await _db.batch((b) {
      b.insertAll(
        _db.readings,
        readings.map((r) => r.toCompanion(rideId)).toList(),
      );
    });
  });
}

@override
Future<List<SensorReading>> getReadings(
    String rideId, {int? startOffset, int? endOffset}) async {
  final query = _db.select(_db.readings)
    ..where((t) {
      final conditions = [t.rideId.equals(rideId)];
      if (startOffset != null) {
        conditions.add(t.offsetSeconds.isBiggerOrEqualValue(startOffset));
      }
      if (endOffset != null) {
        conditions.add(t.offsetSeconds.isSmallerOrEqualValue(endOffset));
      }
      return Expression.and(conditions);
    })
    ..orderBy([(t) => OrderingTerm.asc(t.offsetSeconds)]);

  final rows = await query.get();
  return rows.map((r) => SensorReading.fromRow(r)).toList();
}
```

### IG16.2 Custom Index Definition

Drift doesn't support composite indexes directly in table definitions. Define them in the database class:

```dart
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
    onCreate: (m) async {
      await m.createAll();
      // Custom composite indexes
      await customStatement(
        'CREATE INDEX idx_readings_ride_offset '
        'ON readings (ride_id, offset_seconds)',
      );
      await customStatement(
        'CREATE INDEX idx_rides_start_time '
        'ON rides (start_time DESC)',
      );
      await customStatement(
        'CREATE INDEX idx_efforts_ride '
        'ON efforts (ride_id)',
      );
      await customStatement(
        'CREATE INDEX idx_map_curves_effort '
        'ON map_curves (effort_id)',
      );
      await customStatement(
        'CREATE INDEX idx_ride_tags_tag '
        'ON ride_tags (tag)',
      );
    },
    onUpgrade: (m, from, to) async {
      // Future migrations
    },
  );
}
```

### IG16.3 Remaining Drift Tables

For completeness, the tables not shown in IG8:

```dart
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class Devices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get displayName => text()();
  TextColumn get supportedServices => text()(); // JSON: '["power","heartRate"]'
  DateTimeColumn get lastConnected => dateTime()();
  BoolColumn get autoConnect =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {deviceId};
}

class AutolapConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get startDeltaWatts => real()();
  IntColumn get startConfirmSeconds =>
      integer().withDefault(const Constant(2))();
  IntColumn get startDropoutTolerance =>
      integer().withDefault(const Constant(1))();
  RealColumn get endDeltaWatts => real()();
  IntColumn get endConfirmSeconds =>
      integer().withDefault(const Constant(5))();
  IntColumn get minEffortSeconds =>
      integer().withDefault(const Constant(3))();
  IntColumn get preEffortBaselineWindow =>
      integer().withDefault(const Constant(15))();
  IntColumn get inEffortTrailingWindow =>
      integer().withDefault(const Constant(10))();
  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```
