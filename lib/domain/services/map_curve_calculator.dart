import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

class MapCurveCalculator {
  // --- Batch ---
  static MapCurve computeBatch(List<SensorReading> readings, String entityId) {
    final n = readings.length;
    final values = List<double>.filled(90, 0);
    final flags = List<MapCurveFlags>.generate(
      90,
      (_) => const MapCurveFlags(),
    );

    if (n == 0) {
      return MapCurve(
        entityId: entityId,
        values: values,
        flags: flags,
        computedAt: DateTime.now(),
      );
    }

    // Build parallel prefix sums for null handling.
    // powerSum[i] = sum of non-null power in readings[0..i-1]
    // countSum[i] = count of non-null power in readings[0..i-1]
    final powerSum = List<double>.filled(n + 1, 0);
    final countSum = List<int>.filled(n + 1, 0);

    for (var i = 0; i < n; i++) {
      final p = readings[i].power;
      powerSum[i + 1] = powerSum[i] + (p ?? 0.0);
      countSum[i + 1] = countSum[i] + (p != null ? 1 : 0);
    }

    // For each duration d (1..90), find the best window average.
    for (var d = 1; d <= 90; d++) {
      var bestAvg = 0.0;
      var bestHadNulls = false;

      if (d > n) {
        // Duration longer than data — use entire data as single window.
        final nonNull = countSum[n];
        if (nonNull > 0) {
          bestAvg = powerSum[n] / nonNull;
          bestHadNulls = nonNull < n;
        }
      } else {
        // Slide window of size d across all positions.
        for (var end = d; end <= n; end++) {
          final start = end - d;
          final nonNull = countSum[end] - countSum[start];

          if (nonNull == 0) continue; // all-null window → 0, skip

          final avg = (powerSum[end] - powerSum[start]) / nonNull;
          if (avg > bestAvg) {
            bestAvg = avg;
            bestHadNulls = nonNull < d;
          }
        }
      }

      values[d - 1] = bestAvg;
      flags[d - 1] = MapCurveFlags(hadNulls: bestHadNulls);
    }

    // Monotonicity enforcement: sweep right-to-left.
    for (var i = 88; i >= 0; i--) {
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
    // Append new reading.
    _readings.add(reading.power);
    final p = reading.power;
    _powerSum.add(_powerSum.last + (p ?? 0.0));
    _countSum.add(_countSum.last + (p != null ? 1 : 0));

    final n = _readings.length;
    final values = List<double>.filled(90, 0);
    final flags = List<MapCurveFlags>.generate(
      90,
      (_) => const MapCurveFlags(),
    );

    for (var d = 1; d <= 90; d++) {
      var bestAvg = 0.0;
      var bestHadNulls = false;

      if (d > n) {
        final nonNull = _countSum[n];
        if (nonNull > 0) {
          bestAvg = _powerSum[n] / nonNull;
          bestHadNulls = nonNull < n;
        }
      } else {
        for (var end = d; end <= n; end++) {
          final start = end - d;
          final nonNull = _countSum[end] - _countSum[start];
          if (nonNull == 0) continue;
          final avg = (_powerSum[end] - _powerSum[start]) / nonNull;
          if (avg > bestAvg) {
            bestAvg = avg;
            bestHadNulls = nonNull < d;
          }
        }
      }

      values[d - 1] = bestAvg;
      flags[d - 1] = MapCurveFlags(hadNulls: bestHadNulls);
    }

    // Monotonicity enforcement.
    for (var i = 88; i >= 0; i--) {
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
      ..add(0);
    _countSum
      ..clear()
      ..add(0);
  }
}
