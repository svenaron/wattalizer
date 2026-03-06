import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:wattalizer/data/debug/synthetic_power.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/domain/services/map_curve_calculator.dart';
import 'package:wattalizer/domain/services/summary_calculator.dart';

class DebugSeeder {
  const DebugSeeder(this._repository);
  final RideRepository _repository;

  Future<void> seed() async {
    try {
      for (var i = 0; i < _rideSpecs.length; i++) {
        await _generateAndPersistRide(_rideSpecs[i], seed: i);
      }
    } catch (e) {
      debugPrint('[DebugSeeder] Failed: $e');
      rethrow;
    }
  }

  Future<void> _generateAndPersistRide(
    _RideSpec spec, {
    required int seed,
  }) async {
    final rng = math.Random(seed);
    final durationSeconds = spec.durationMinutes * 60;

    // Start time: days ago + random morning hour (06:00–09:30).
    final now = DateTime.now();
    final baseDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: spec.daysAgo));
    final startHour = 6 + rng.nextInt(4); // 6–9
    final startMinute = rng.nextInt(startHour == 9 ? 31 : 60);
    final startTime = baseDay.add(
      Duration(hours: startHour, minutes: startMinute),
    );
    final endTime = startTime.add(Duration(seconds: durationSeconds));

    // Place efforts.
    final effortWindows = _placeEfforts(
      durationSeconds: durationSeconds,
      effortCount: spec.effortCount,
      rng: rng,
    );

    // Generate power data.
    final powerData = generateRidePower(
      durationSeconds: durationSeconds,
      efforts: effortWindows,
      baselineWatts: spec.baselineWatts,
      peakWatts: spec.peakWatts,
      seed: seed,
    );

    // Build sensor readings.
    final readings = _buildReadings(
      durationSeconds: durationSeconds,
      powerData: powerData,
      effortWindows: effortWindows,
      rng: rng,
    );

    // Build efforts with summaries and MAP curves.
    final rideId = 'seed-ride-$seed';
    final efforts = <Effort>[];
    int? prevEndOffset;

    for (var i = 0; i < effortWindows.length; i++) {
      final w = effortWindows[i];
      final effortId = 'seed-effort-$seed-$i';
      final effortReadings = readings
          .where(
            (r) =>
                r.timestamp.inSeconds >= w.startOffset &&
                r.timestamp.inSeconds < w.startOffset + w.durationSeconds,
          )
          .toList();

      var summary = SummaryCalculator.computeEffortSummary(effortReadings);
      if (prevEndOffset != null) {
        summary = summary.copyWith(
          restSincePrevious: w.startOffset - prevEndOffset,
        );
      }

      final mapCurve = MapCurveCalculator.computeBatch(
        effortReadings,
        effortId,
      );

      efforts.add(
        Effort(
          id: effortId,
          rideId: rideId,
          effortNumber: i + 1,
          startOffset: w.startOffset,
          endOffset: w.startOffset + w.durationSeconds - 1,
          type: EffortType.auto,
          summary: summary,
          mapCurve: mapCurve,
        ),
      );

      prevEndOffset = w.startOffset + w.durationSeconds - 1;
    }

    // Compute ride summary.
    final rideSummary = SummaryCalculator.computeRideSummary(readings, efforts);

    final ride = Ride(
      id: rideId,
      startTime: startTime,
      endTime: endTime,
      source: RideSource.recorded,
      tags: spec.tags,
      notes: spec.notes,
      summary: rideSummary,
      efforts: efforts,
    );

    // Persist through the repository interface.
    await _repository.transaction(() async {
      await _repository.saveRide(ride);
      await _repository.insertReadings(rideId, readings);
      await _repository.saveEfforts(rideId, efforts);
    });
  }
}

// ---------------------------------------------------------------------------
// Ride specifications
// ---------------------------------------------------------------------------

class _RideSpec {
  const _RideSpec({
    required this.daysAgo,
    required this.durationMinutes,
    required this.tags,
    required this.effortCount,
    required this.baselineWatts,
    required this.peakWatts,
    this.notes,
  });

  final int daysAgo;
  final int durationMinutes;
  final List<String> tags;
  final int effortCount;
  final double baselineWatts;
  final double peakWatts;
  final String? notes;
}

const _rideSpecs = [
  _RideSpec(
    daysAgo: 0,
    durationMinutes: 62,
    tags: ['track', 'flying 200'],
    effortCount: 6,
    baselineWatts: 80,
    peakWatts: 1180,
    notes: "Today's session",
  ),
  _RideSpec(
    daysAgo: 1,
    durationMinutes: 45,
    tags: ['trainer', 'short sprint'],
    effortCount: 4,
    baselineWatts: 70,
    peakWatts: 1040,
  ),
  _RideSpec(
    daysAgo: 3,
    durationMinutes: 78,
    tags: ['track', 'team sprint', 'outdoor'],
    effortCount: 8,
    baselineWatts: 85,
    peakWatts: 1240,
    notes: 'Many efforts',
  ),
  _RideSpec(
    daysAgo: 5,
    durationMinutes: 55,
    tags: ['trainer'],
    effortCount: 5,
    baselineWatts: 65,
    peakWatts: 980,
  ),
  _RideSpec(
    daysAgo: 7,
    durationMinutes: 68,
    tags: ['track', 'flying 200'],
    effortCount: 6,
    baselineWatts: 80,
    peakWatts: 1150,
  ),
  _RideSpec(
    daysAgo: 10,
    durationMinutes: 40,
    tags: ['track'],
    effortCount: 3,
    baselineWatts: 75,
    peakWatts: 1090,
    notes: 'Short session',
  ),
  _RideSpec(
    daysAgo: 14,
    durationMinutes: 72,
    tags: ['trainer', 'team sprint'],
    effortCount: 7,
    baselineWatts: 70,
    peakWatts: 1200,
  ),
  _RideSpec(
    daysAgo: 18,
    durationMinutes: 50,
    tags: ['outdoor'],
    effortCount: 4,
    baselineWatts: 60,
    peakWatts: 920,
    notes: 'Lower power day',
  ),
  _RideSpec(
    daysAgo: 22,
    durationMinutes: 65,
    tags: ['track', 'flying 200'],
    effortCount: 5,
    baselineWatts: 80,
    peakWatts: 1160,
  ),
  _RideSpec(
    daysAgo: 30,
    durationMinutes: 80,
    tags: ['track', 'outdoor'],
    effortCount: 9,
    baselineWatts: 85,
    peakWatts: 1260,
    notes: 'Best session',
  ),
  _RideSpec(
    daysAgo: 45,
    durationMinutes: 58,
    tags: ['trainer'],
    effortCount: 5,
    baselineWatts: 70,
    peakWatts: 1010,
  ),
  _RideSpec(
    daysAgo: 60,
    durationMinutes: 70,
    tags: ['track', 'team sprint'],
    effortCount: 6,
    baselineWatts: 80,
    peakWatts: 1190,
  ),
  _RideSpec(
    daysAgo: 90,
    durationMinutes: 48,
    tags: ['trainer', 'short sprint'],
    effortCount: 4,
    baselineWatts: 65,
    peakWatts: 950,
  ),
  _RideSpec(
    daysAgo: 120,
    durationMinutes: 75,
    tags: ['track', 'outdoor'],
    effortCount: 7,
    baselineWatts: 82,
    peakWatts: 1220,
  ),
];

// ---------------------------------------------------------------------------
// Effort placement
// ---------------------------------------------------------------------------

List<({int startOffset, int durationSeconds})> _placeEfforts({
  required int durationSeconds,
  required int effortCount,
  required math.Random rng,
}) {
  if (effortCount == 0) return [];

  const minStartOffset = 120; // no effort in first 2 min
  const minEndGap = 180; // no effort in last 3 min
  const minGap = 30; // minimum 30s recovery between efforts

  final usable = durationSeconds - minStartOffset - minEndGap;
  if (usable <= 0) return [];

  final slotWidth = usable ~/ effortCount;
  final results = <({int startOffset, int durationSeconds})>[];

  for (var i = 0; i < effortCount; i++) {
    final slotStart = minStartOffset + i * slotWidth;
    final jitter = rng.nextInt(math.max(1, (slotWidth * 0.3).toInt()));
    final effortDuration = rng.nextInt(15) + 8; // 8–22s
    var offset = slotStart + jitter;

    // Ensure minimum gap from previous effort.
    if (results.isNotEmpty) {
      final prev = results.last;
      final prevEnd = prev.startOffset + prev.durationSeconds;
      if (offset < prevEnd + minGap) {
        offset = prevEnd + minGap;
      }
    }

    // Ensure effort fits before the end gap.
    if (offset + effortDuration > durationSeconds - minEndGap) break;

    results.add((startOffset: offset, durationSeconds: effortDuration));
  }

  return results;
}

// ---------------------------------------------------------------------------
// Sensor reading builder
// ---------------------------------------------------------------------------

List<SensorReading> _buildReadings({
  required int durationSeconds,
  required List<double?> powerData,
  required List<({int startOffset, int durationSeconds})> effortWindows,
  required math.Random rng,
}) {
  // Build effort offset set for quick lookup.
  final effortOffsets = <int>{};
  for (final e in effortWindows) {
    for (var t = e.startOffset; t < e.startOffset + e.durationSeconds; t++) {
      effortOffsets.add(t);
    }
  }

  var currentHr = 85.0;
  final readings = <SensorReading>[];

  for (var t = 0; t < durationSeconds; t++) {
    final inEffort = effortOffsets.contains(t);

    // Heart rate: ramp up during effort, decay after.
    if (inEffort) {
      final targetHr = 165.0 + rng.nextInt(21); // 165–185
      if (currentHr < targetHr) {
        currentHr = math.min(targetHr, currentHr + (targetHr - 85) / 8);
      }
    } else {
      currentHr = math.max(85, currentHr - (currentHr - 85) * 0.05);
    }
    final hr = (currentHr + rng.nextInt(11) - 5).round().clamp(40, 220);

    // Cadence: null for first 2s of effort (sensor spin-up).
    double? cadence;
    if (inEffort) {
      var isSpinUp = false;
      for (final e in effortWindows) {
        if (t >= e.startOffset && t < e.startOffset + 2) {
          isSpinUp = true;
          break;
        }
      }
      cadence = isSpinUp ? null : 90.0 + rng.nextDouble() * 5;
    } else {
      cadence = 60.0 + rng.nextDouble() * 10;
    }

    readings.add(
      SensorReading(
        timestamp: Duration(seconds: t),
        power: powerData[t],
        heartRate: hr,
        cadence: cadence,
      ),
    );
  }

  return readings;
}
