import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/domain/services/map_curve_calculator.dart';

void main() {
  group('MapCurveCalculator.computeBatch', () {
    test('IG4.2 worked example produces expected values', () {
      // [100, 800, null, null, 500, 600]
      final readings = [
        _r(0, power: 100),
        _r(1, power: 800),
        _r(2),
        _r(3),
        _r(4, power: 500),
        _r(5, power: 600),
      ];
      final curve = MapCurveCalculator.computeBatch(readings, 'test');

      // 1s best = 800 (no nulls)
      expect(curve.values[0], closeTo(800.0, 0.01));
      expect(curve.flags[0].hadNulls, false);

      // 2s best = 800 (window [800,null]: 1 non-null,
      // 800/1=800, hadNulls=true)
      expect(curve.values[1], closeTo(800.0, 0.01));
      expect(curve.flags[1].hadNulls, true);

      // 3s best = 800 (window [800,null,null]: 1 non-null → 800)
      expect(curve.values[2], closeTo(800.0, 0.01));
      expect(curve.flags[2].hadNulls, true);

      // 4s best = 650 (window [800,null,null,500]: 2 non-null → 1300/2=650)
      expect(curve.values[3], closeTo(650.0, 0.01));
      expect(curve.flags[3].hadNulls, true);

      // 5s best = 633.3 (window [800,null,null,500,600]: 3 non-null → 1900/3)
      expect(curve.values[4], closeTo(1900.0 / 3, 0.01));
      expect(curve.flags[4].hadNulls, true);

      // 6s best = 500 (all 6 readings: 4 non-null → 2000/4=500)
      expect(curve.values[5], closeTo(500.0, 0.01));
      expect(curve.flags[5].hadNulls, true);

      // Durations 7..90: d > n, no valid window → 0
      for (var i = 6; i < 90; i++) {
        expect(curve.values[i], 0.0);
      }
    });

    test('empty readings produces all zeros', () {
      final curve = MapCurveCalculator.computeBatch([], 'test');
      expect(curve.values.length, 90);
      expect(curve.values.every((v) => v == 0.0), true);
    });

    test('all-null readings produce all zeros', () {
      final readings = [_r(0), _r(1), _r(2)];
      final curve = MapCurveCalculator.computeBatch(readings, 'test');
      for (final v in curve.values) {
        expect(v, 0.0);
      }
    });

    test('output is monotonically non-increasing', () {
      final rng = Random(42);
      final readings = List.generate(
        30,
        (i) => _r(i, power: rng.nextDouble() * 1500),
      );
      final curve = MapCurveCalculator.computeBatch(readings, 'test');

      for (var i = 0; i < 89; i++) {
        expect(
          curve.values[i],
          greaterThanOrEqualTo(curve.values[i + 1]),
          reason: 'values[$i]=${curve.values[i]} < '
              'values[${i + 1}]=${curve.values[i + 1]}',
        );
      }
    });

    test('hadNulls flag set when best window contains a null', () {
      final readings = [_r(0, power: 100), _r(1, power: 800), _r(2)];
      final curve = MapCurveCalculator.computeBatch(readings, 'test');

      // 1s best = 800 — window [800] has no nulls
      expect(curve.flags[0].hadNulls, false);
      // 2s best = 800 — window [800, null] has a null
      expect(curve.flags[1].hadNulls, true);
    });

    test('wasEnforced flag set when monotonicity bumps a value', () {
      final curve = MapCurveCalculator.computeBatch(
        [
          _r(0, power: 100),
          _r(1, power: 100),
          _r(2, power: 800),
        ],
        'test',
      );

      // Wherever enforcement occurred, values[i] == values[i+1]
      for (var i = 0; i < 89; i++) {
        if (curve.flags[i].wasEnforced) {
          expect(curve.values[i], curve.values[i + 1]);
        }
      }
    });

    test('uniform readings: 1s best equals the constant value', () {
      final readings = List.generate(10, (i) => _r(i, power: 400));
      final curve = MapCurveCalculator.computeBatch(readings, 'test');

      // All durations up to 10 should be 400
      for (var i = 0; i < 10; i++) {
        expect(curve.values[i], closeTo(400.0, 0.001));
      }
      // Duration 11..90: d > n, no valid window → 0
      for (var i = 10; i < 90; i++) {
        expect(curve.values[i], 0.0);
      }
    });

    test('entityId and computedAt are set', () {
      final curve = MapCurveCalculator.computeBatch([_r(0, power: 500)], 'eid');
      expect(curve.entityId, 'eid');
      expect(curve.computedAt, isA<DateTime>());
    });
  });

  group('MapCurveCalculator.updateLive', () {
    test('live and batch produce identical results', () {
      final readings = [
        _r(0, power: 500),
        _r(1, power: 1200),
        _r(2),
        _r(3, power: 900),
        _r(4, power: 700),
      ];

      final batchCurve = MapCurveCalculator.computeBatch(readings, 'test');

      final liveCalc = MapCurveCalculator();
      MapCurve? liveCurve;
      for (final r in readings) {
        liveCurve = liveCalc.updateLive(r, 'test');
      }

      for (var i = 0; i < 90; i++) {
        expect(
          liveCurve!.values[i],
          closeTo(batchCurve.values[i], 0.001),
          reason: 'Value mismatch at duration ${i + 1}s',
        );
        expect(
          liveCurve.flags[i].hadNulls,
          batchCurve.flags[i].hadNulls,
          reason: 'hadNulls mismatch at duration ${i + 1}s',
        );
        expect(
          liveCurve.flags[i].wasEnforced,
          batchCurve.flags[i].wasEnforced,
          reason: 'wasEnforced mismatch at duration ${i + 1}s',
        );
      }
    });

    test('live equivalence: IG4.2 worked example', () {
      final readings = [
        _r(0, power: 100),
        _r(1, power: 800),
        _r(2),
        _r(3),
        _r(4, power: 500),
        _r(5, power: 600),
      ];
      final batchCurve = MapCurveCalculator.computeBatch(readings, 'test');

      final liveCalc = MapCurveCalculator();
      MapCurve? liveCurve;
      for (final r in readings) {
        liveCurve = liveCalc.updateLive(r, 'test');
      }

      for (var i = 0; i < 90; i++) {
        expect(
          liveCurve!.values[i],
          closeTo(batchCurve.values[i], 0.001),
          reason: 'duration ${i + 1}s',
        );
      }
    });

    test('reset clears state for reuse', () {
      final calc = MapCurveCalculator()
        ..updateLive(_r(0, power: 1000), 'test')
        ..updateLive(_r(1, power: 1000), 'test')
        ..reset();

      final curve = calc.updateLive(_r(0, power: 500), 'test');
      // After reset, only 1 reading: 1s best = 500
      expect(curve.values[0], closeTo(500.0, 0.001));
      // 2s: d > n, no valid window → 0
      expect(curve.values[1], 0.0);
    });

    test('live output is monotonically non-increasing after each call', () {
      final rng = Random(99);
      final calc = MapCurveCalculator();
      for (var i = 0; i < 20; i++) {
        final curve = calc.updateLive(
          _r(i, power: rng.nextDouble() * 1500),
          'test',
        );
        for (var j = 0; j < 89; j++) {
          expect(
            curve.values[j],
            greaterThanOrEqualTo(curve.values[j + 1]),
            reason: 'After reading $i, values[$j] < values[${j + 1}]',
          );
        }
      }
    });
  });
}

SensorReading _r(int offsetSeconds, {double? power}) {
  return SensorReading(
    timestamp: Duration(seconds: offsetSeconds),
    power: power,
  );
}
