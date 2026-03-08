import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/services/historical_range_calculator.dart';

/// Creates a MapCurveWithProvenance from a list of 5-value curve + fill value.
MapCurveWithProvenance _curve({
  required List<double> values5, // first 5 values; rest filled with last value
  required String effortId,
  required String rideId,
  DateTime? rideDate,
  int effortNumber = 1,
}) {
  final last = values5.last;
  final full = List<double>.generate(
    90,
    (i) => i < values5.length ? values5[i] : last,
  );
  return MapCurveWithProvenance(
    effortId: effortId,
    rideId: rideId,
    rideDate: rideDate ?? DateTime(2026, 2, 20),
    effortNumber: effortNumber,
    curve: MapCurve(
      entityId: effortId,
      values: full,
      flags: List.filled(90, const MapCurveFlags()),
      computedAt: DateTime(2026),
    ),
  );
}

void main() {
  final calculator = HistoricalRangeCalculator();

  group('HistoricalRangeCalculator.compute', () {
    test('empty input: no crash, best/worst are all zeros', () {
      final result = calculator.compute([]);

      expect(result.effortCount, 0);
      expect(result.best.length, 90);
      expect(result.worst.length, 90);
      for (final r in result.best) {
        expect(r.power, 0.0);
      }
      for (final r in result.worst) {
        expect(r.power, 0.0);
      }
    });

    test('single effort: best == worst at each duration', () {
      final c = _curve(
        values5: [1000, 900, 800, 700, 600],
        effortId: 'e1',
        rideId: 'r1',
      );
      final result = calculator.compute([c]);

      expect(result.effortCount, 1);
      for (var i = 0; i < 5; i++) {
        expect(result.best[i].power, closeTo(c.curve.values[i], 0.001));
        expect(result.worst[i].power, closeTo(c.curve.values[i], 0.001));
        expect(result.best[i].effortId, 'e1');
        expect(result.worst[i].effortId, 'e1');
      }
    });

    test('IG5 worked example: best/worst with correct provenance', () {
      // Effort A (ride R1, effort #1): [1400, 1300, 1200, 1100, 1000]
      // Effort B (ride R1, effort #2): [1350, 1280, 1250, 1150, 1050]
      // Effort C (ride R2, effort #1): [1420, 1290, 1180, 1080, 980]
      final effortA = _curve(
        values5: [1400, 1300, 1200, 1100, 1000],
        effortId: 'A',
        rideId: 'R1',
        rideDate: DateTime(2026, 2, 20),
      );
      final effortB = _curve(
        values5: [1350, 1280, 1250, 1150, 1050],
        effortId: 'B',
        rideId: 'R1',
        rideDate: DateTime(2026, 2, 20),
        effortNumber: 2,
      );
      final effortC = _curve(
        values5: [1420, 1290, 1180, 1080, 980],
        effortId: 'C',
        rideId: 'R2',
        rideDate: DateTime(2026, 2, 24),
      );

      final result = calculator.compute([effortA, effortB, effortC]);

      expect(result.effortCount, 3);

      // Best envelope from IG5:
      // d=0(1s): max=1420 (C)
      expect(result.best[0].power, closeTo(1420, 0.001));
      expect(result.best[0].effortId, 'C');

      // d=1(2s): max=1300 (A)
      expect(result.best[1].power, closeTo(1300, 0.001));
      expect(result.best[1].effortId, 'A');

      // d=2(3s): max=1250 (B)
      expect(result.best[2].power, closeTo(1250, 0.001));
      expect(result.best[2].effortId, 'B');

      // d=3(4s): max=1150 (B)
      expect(result.best[3].power, closeTo(1150, 0.001));
      expect(result.best[3].effortId, 'B');

      // d=4(5s): max=1050 (B)
      expect(result.best[4].power, closeTo(1050, 0.001));
      expect(result.best[4].effortId, 'B');

      // Worst envelope from IG5:
      // d=0(1s): min=1350 (B)
      expect(result.worst[0].power, closeTo(1350, 0.001));
      expect(result.worst[0].effortId, 'B');

      // d=1(2s): min=1280 (B)
      expect(result.worst[1].power, closeTo(1280, 0.001));
      expect(result.worst[1].effortId, 'B');

      // d=2(3s): min=1180 (C)
      expect(result.worst[2].power, closeTo(1180, 0.001));
      expect(result.worst[2].effortId, 'C');

      // d=3(4s): min=1080 (C)
      expect(result.worst[3].power, closeTo(1080, 0.001));
      expect(result.worst[3].effortId, 'C');

      // d=4(5s): min=980 (C)
      expect(result.worst[4].power, closeTo(980, 0.001));
      expect(result.worst[4].effortId, 'C');
    });

    test('best envelope is monotonically non-increasing', () {
      final curves = [
        _curve(
          values5: [1000, 900, 800, 700, 600],
          effortId: 'e1',
          rideId: 'r1',
        ),
        _curve(
          values5: [800, 1000, 900, 600, 700],
          effortId: 'e2',
          rideId: 'r1',
        ),
        _curve(
          values5: [900, 800, 1000, 800, 500],
          effortId: 'e3',
          rideId: 'r1',
        ),
      ];

      final result = calculator.compute(curves);

      for (var i = 0; i < 89; i++) {
        expect(
          result.best[i].power,
          greaterThanOrEqualTo(result.best[i + 1].power),
          reason: 'best[$i]=${result.best[i].power} < '
              'best[${i + 1}]=${result.best[i + 1].power}',
        );
        expect(
          result.worst[i].power,
          greaterThanOrEqualTo(result.worst[i + 1].power),
          reason: 'worst[$i]=${result.worst[i].power} < '
              'worst[${i + 1}]=${result.worst[i + 1].power}',
        );
      }
    });

    test(
      'provenance inherited when monotonicity enforcement bumps best value',
      () {
        // d=0: best=900 (e1), d=1: best=950 (e2)
        // After enforcement: best[0] bumped to 950,
        // should inherit e2 provenance
        final e1 = _curve(
          values5: [900, 800, 700, 600, 500],
          effortId: 'e1',
          rideId: 'r1',
        );
        final e2 = _curve(
          values5: [800, 950, 700, 600, 500],
          effortId: 'e2',
          rideId: 'r1',
        );

        final result = calculator.compute([e1, e2]);

        // Before enforcement: best[0]=900(e1), best[1]=950(e2)
        // Enforcement: 900 < 950 → best[0] bumped to 950, inherits e2
        expect(result.best[0].power, closeTo(950, 0.001));
        expect(result.best[0].effortId, 'e2'); // provenance inherited from e2
        expect(result.best[1].power, closeTo(950, 0.001));
        expect(result.best[1].effortId, 'e2');
      },
    );

    test('topN=2: worst is 2nd-best, not all-time worst', () {
      // 3 efforts at 1s: 1000, 800, 200 → top2 = [1000, 800]; worst = 800
      final e1 = _curve(
        values5: [1000, 900, 800, 700, 600],
        effortId: 'e1',
        rideId: 'r1',
      );
      final e2 = _curve(
        values5: [800, 750, 700, 650, 600],
        effortId: 'e2',
        rideId: 'r1',
      );
      final e3 = _curve(
        values5: [200, 190, 180, 170, 160],
        effortId: 'e3',
        rideId: 'r1',
      );

      final result = calculator.compute([e1, e2, e3], topN: 2);

      expect(result.best[0].power, closeTo(1000, 0.001));
      expect(result.best[0].effortId, 'e1');
      // worst = 2nd-best = 800, not 200
      expect(result.worst[0].power, closeTo(800, 0.001));
      expect(result.worst[0].effortId, 'e2');
    });

    test('fewer efforts than topN: worst = weakest available', () {
      final e1 = _curve(
        values5: [1000, 900, 800, 700, 600],
        effortId: 'e1',
        rideId: 'r1',
      );
      final e2 = _curve(
        values5: [800, 750, 700, 650, 600],
        effortId: 'e2',
        rideId: 'r1',
      );

      // Default topN=10 but only 2 efforts → worst = 2nd-best (e2)
      final result = calculator.compute([e1, e2]);

      expect(result.best[0].power, closeTo(1000, 0.001));
      expect(result.worst[0].power, closeTo(800, 0.001));
      expect(result.worst[0].effortId, 'e2');
    });

    test('default topN=10: with 5 efforts worst = 5th-best', () {
      final curves = List.generate(
        5,
        (i) => _curve(
          values5: [
            (1000 - i * 100).toDouble(),
            (900 - i * 100).toDouble(),
            (800 - i * 100).toDouble(),
            (700 - i * 100).toDouble(),
            (600 - i * 100).toDouble(),
          ],
          effortId: 'e$i',
          rideId: 'r1',
        ),
      );

      // topN=10, only 5 efforts → worst = weakest of the 5 = e4 with 600
      final result = calculator.compute(curves);

      expect(result.best[0].power, closeTo(1000, 0.001));
      expect(result.worst[0].power, closeTo(600, 0.001));
      expect(result.worst[0].effortId, 'e4');
    });

    test('durationSeconds in records matches index+1', () {
      final c = _curve(
        values5: [1000, 900, 800, 700, 600],
        effortId: 'e1',
        rideId: 'r1',
      );
      final result = calculator.compute([c]);

      for (var i = 0; i < 90; i++) {
        expect(result.best[i].durationSeconds, i + 1);
        expect(result.worst[i].durationSeconds, i + 1);
      }
    });
  });
}
