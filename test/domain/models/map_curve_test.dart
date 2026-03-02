import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/map_curve.dart';

void main() {
  group('MapCurveFlags', () {
    test('defaults to hadNulls=false, wasEnforced=false', () {
      const f = MapCurveFlags();
      expect(f.hadNulls, isFalse);
      expect(f.wasEnforced, isFalse);
    });

    test('can be set to true', () {
      const f = MapCurveFlags(hadNulls: true, wasEnforced: true);
      expect(f.hadNulls, isTrue);
      expect(f.wasEnforced, isTrue);
    });
  });

  group('MapCurve', () {
    late MapCurve curve;

    setUp(() {
      curve = MapCurve(
        entityId: 'effort_1',
        values: List.generate(90, (i) => (90 - i).toDouble()),
        flags: List.generate(90, (_) => const MapCurveFlags()),
        computedAt: DateTime(2026, 3),
      );
    });

    test('has exactly 90 values', () {
      expect(curve.values, hasLength(90));
    });

    test('has exactly 90 flags', () {
      expect(curve.flags, hasLength(90));
    });

    test('index 0 corresponds to 1-second best (highest value)', () {
      // By convention values[0] = 1s best, values[89] = 90s best
      expect(curve.values[0], greaterThanOrEqualTo(curve.values[89]));
    });

    test('entityId is preserved', () {
      expect(curve.entityId, 'effort_1');
    });

    test('computedAt is preserved', () {
      expect(curve.computedAt, DateTime(2026, 3));
    });
  });
}
