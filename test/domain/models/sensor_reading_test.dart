import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

void main() {
  group('SensorReading', () {
    test('const constructor sets all required fields', () {
      const r = SensorReading(timestamp: Duration(seconds: 5));
      expect(r.timestamp, const Duration(seconds: 5));
      expect(r.power, isNull);
      expect(r.heartRate, isNull);
    });

    test('null power means sensor dropout (distinct from zero)', () {
      const dropout = SensorReading(timestamp: Duration(seconds: 1));
      const coasting = SensorReading(timestamp: Duration(seconds: 2), power: 0);
      expect(dropout.power, isNull);
      expect(coasting.power, 0.0);
    });

    group('copyWith', () {
      const base = SensorReading(
        timestamp: Duration(seconds: 10),
        power: 500,
        heartRate: 160,
        cadence: 95,
      );

      test('returns identical values when called with no arguments', () {
        final copy = base.copyWith();
        expect(copy.timestamp, base.timestamp);
        expect(copy.power, base.power);
        expect(copy.heartRate, base.heartRate);
        expect(copy.cadence, base.cadence);
      });

      test('overrides specific fields', () {
        final copy = base.copyWith(power: 600.0);
        expect(copy.power, 600.0);
        expect(copy.heartRate, base.heartRate); // unchanged
      });

      test('can explicitly set a field to null', () {
        final copy = base.copyWith(power: null);
        expect(copy.power, isNull);
        expect(copy.heartRate, base.heartRate); // unchanged
      });

      test('updates timestamp', () {
        final copy = base.copyWith(timestamp: const Duration(seconds: 20));
        expect(copy.timestamp, const Duration(seconds: 20));
      });
    });

    test('rrIntervals can be a list', () {
      const r = SensorReading(
        timestamp: Duration.zero,
        rrIntervals: [800, 810, 795],
      );
      expect(r.rrIntervals, [800, 810, 795]);
    });
  });
}
