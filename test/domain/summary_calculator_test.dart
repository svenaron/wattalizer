import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/domain/services/summary_calculator.dart';

void main() {
  group('SummaryCalculator.computeEffortSummary', () {
    test('empty readings returns zeroed EffortSummary', () {
      final summary = SummaryCalculator.computeEffortSummary([]);

      expect(summary.durationSeconds, 0);
      expect(summary.avgPower, 0.0);
      expect(summary.peakPower, 0.0);
      expect(summary.totalKilojoules, 0.0);
      expect(summary.avgHeartRate, isNull);
      expect(summary.maxHeartRate, isNull);
      expect(summary.avgCadence, isNull);
    });

    test('all-null power yields avgPower=0 and peakPower=0', () {
      final readings = [_r(0, hr: 150), _r(1, hr: 155)];
      final summary = SummaryCalculator.computeEffortSummary(readings);

      expect(summary.avgPower, 0.0);
      expect(summary.peakPower, 0.0);
      expect(summary.durationSeconds, 2);
      // HR still computed
      expect(summary.avgHeartRate, 153);
    });

    test('IG13.1 effort example: [800, 900, 850, 750] at t=2..5', () {
      final readings = [
        _r(2, power: 800, hr: 155),
        _r(3, power: 900, hr: 165),
        _r(4, power: 850, hr: 170),
        _r(5, power: 750, hr: 172),
      ];
      final summary = SummaryCalculator.computeEffortSummary(readings);

      expect(summary.durationSeconds, 4); // 5 - 2 + 1
      expect(summary.avgPower, closeTo(825.0, 0.001));
      expect(summary.peakPower, 900.0);
      expect(summary.avgHeartRate, 166); // round(165.5)
      expect(summary.maxHeartRate, 172);
      expect(summary.totalKilojoules, closeTo(825.0 * 4 / 1000, 0.001));
    });

    test('mixed null power: only non-null contribute to avg', () {
      final readings = [_r(0, power: 400), _r(1), _r(2, power: 600)];
      final summary = SummaryCalculator.computeEffortSummary(readings);

      // avg = (400+600)/2 = 500, not 1000/3
      expect(summary.avgPower, closeTo(500.0, 0.001));
      expect(summary.peakPower, 600.0);
      expect(summary.durationSeconds, 3);
    });

    test('kJ = avgPower * duration / 1000', () {
      final readings = [
        _r(0, power: 1000),
        _r(1, power: 1000),
        _r(2, power: 1000),
      ];
      final summary = SummaryCalculator.computeEffortSummary(readings);

      expect(summary.totalKilojoules, closeTo(3.0, 0.001)); // 1000*3/1000
    });

    test('no HR readings → avgHeartRate and maxHeartRate are null', () {
      final readings = [_r(0, power: 500)];
      final summary = SummaryCalculator.computeEffortSummary(readings);

      expect(summary.avgHeartRate, isNull);
      expect(summary.maxHeartRate, isNull);
    });

    test('no cadence readings → avgCadence is null', () {
      final readings = [_r(0, power: 500, hr: 160)];
      final summary = SummaryCalculator.computeEffortSummary(readings);

      expect(summary.avgCadence, isNull);
    });

    test('cadence averaged across readings', () {
      final readings = [
        _r(0, power: 500, cadence: 100),
        _r(1, power: 500, cadence: 120),
      ];
      final summary = SummaryCalculator.computeEffortSummary(readings);

      expect(summary.avgCadence, closeTo(110.0, 0.001));
    });
  });

  group('SummaryCalculator.computeRideSummary', () {
    test('empty readings returns zeroed RideSummary', () {
      final summary = SummaryCalculator.computeRideSummary([], []);

      expect(summary.durationSeconds, 0);
      expect(summary.activeDurationSeconds, 0);
      expect(summary.avgPower, 0.0);
      expect(summary.maxPower, 0.0);
      expect(summary.readingCount, 0);
      expect(summary.effortCount, 0);
    });

    test('IG13.1 ride example: recovery excluded from averages', () {
      // t=0,1: recovery; t=2..5: effort; t=6..9: recovery (t=8 null power)
      final allReadings = [
        _r(0, power: 100, hr: 140),
        _r(1, power: 120, hr: 142),
        _r(2, power: 800, hr: 155),
        _r(3, power: 900, hr: 165),
        _r(4, power: 850, hr: 170),
        _r(5, power: 750, hr: 172),
        _r(6, power: 150, hr: 168),
        _r(7, power: 130, hr: 160),
        _r(8, hr: 155),
        _r(9, power: 110, hr: 150),
      ];
      final efforts = [_effort(startOffset: 2, endOffset: 5)];
      final summary = SummaryCalculator.computeRideSummary(
        allReadings,
        efforts,
      );

      expect(summary.durationSeconds, 10); // 9 - 0 + 1
      expect(summary.activeDurationSeconds, 4); // offsets 2,3,4,5
      expect(summary.avgPower, closeTo(825.0, 0.001)); // active only
      expect(summary.maxPower, 900.0); // entire ride
      expect(
        summary.avgHeartRate,
        166,
      ); // active only: (155+165+170+172)/4=165.5 → 166
      expect(summary.maxHeartRate, 172); // entire ride
      expect(summary.totalKilojoules, closeTo(825.0 * 4 / 1000, 0.001));
      expect(summary.readingCount, 10);
      expect(summary.effortCount, 1);
    });

    test('zero efforts: activeDurationSeconds=0, avgPower=0', () {
      final allReadings = [_r(0, power: 300), _r(1, power: 400)];
      final summary = SummaryCalculator.computeRideSummary(allReadings, []);

      expect(summary.activeDurationSeconds, 0);
      expect(summary.avgPower, 0.0);
      expect(summary.totalKilojoules, 0.0);
      expect(summary.maxPower, 400.0); // still scans entire ride
      expect(summary.durationSeconds, 2);
    });

    test('maxPower includes recovery readings even if higher', () {
      final allReadings = [
        _r(0, power: 2000), // recovery — highest power
        _r(1, power: 800), // effort
        _r(2, power: 900), // effort
      ];
      final efforts = [_effort(startOffset: 1, endOffset: 2)];
      final summary = SummaryCalculator.computeRideSummary(
        allReadings,
        efforts,
      );

      expect(summary.maxPower, 2000.0); // from recovery
      expect(summary.avgPower, closeTo(850.0, 0.001)); // active only
    });

    test('multiple efforts: active offsets union of all effort ranges', () {
      final allReadings = List.generate(
        10,
        (i) => _r(i, power: 100.0 * (i + 1)),
      );
      // Effort 1: t=1..3, Effort 2: t=6..8
      final efforts = [
        _effort(startOffset: 1, endOffset: 3),
        _effort(startOffset: 6, endOffset: 8),
      ];
      final summary = SummaryCalculator.computeRideSummary(
        allReadings,
        efforts,
      );

      expect(summary.activeDurationSeconds, 6); // offsets 1,2,3,6,7,8
      expect(summary.effortCount, 2);
    });
  });
}

SensorReading _r(int offsetSeconds, {double? power, int? hr, double? cadence}) {
  return SensorReading(
    timestamp: Duration(seconds: offsetSeconds),
    power: power,
    heartRate: hr,
    cadence: cadence,
  );
}

/// Creates a minimal Effort for testing RideSummary
/// (summary and mapCurve fields unused).
Effort _effort({required int startOffset, required int endOffset}) {
  return Effort(
    id: 'e',
    rideId: 'r',
    effortNumber: 1,
    startOffset: startOffset,
    endOffset: endOffset,
    type: EffortType.auto,
    summary: const EffortSummary(
      durationSeconds: 0,
      avgPower: 0,
      peakPower: 0,
      totalKilojoules: 0,
    ),
    mapCurve: MapCurve(
      entityId: 'e',
      values: List.filled(90, 0),
      flags: List.filled(90, const MapCurveFlags()),
      computedAt: DateTime(2026),
    ),
  );
}
