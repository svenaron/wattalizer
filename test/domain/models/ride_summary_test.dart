import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';

void main() {
  group('RideSummary', () {
    test('constructs with required fields', () {
      const s = RideSummary(
        durationSeconds: 3600,
        activeDurationSeconds: 120,
        avgPower: 450,
        maxPower: 1200,
        readingCount: 3600,
        effortCount: 3,
      );
      expect(s.durationSeconds, 3600);
      expect(s.activeDurationSeconds, 120);
      expect(s.avgPower, 450.0);
      expect(s.maxPower, 1200.0);
    });

    test('optional fields default to null', () {
      const s = RideSummary(
        durationSeconds: 0,
        activeDurationSeconds: 0,
        avgPower: 0,
        maxPower: 0,
        readingCount: 0,
        effortCount: 0,
      );
      expect(s.avgHeartRate, isNull);
      expect(s.maxHeartRate, isNull);
      expect(s.avgCadence, isNull);
      expect(s.avgLeftRightBalance, isNull);
    });

    test('optional fields can be provided', () {
      const s = RideSummary(
        durationSeconds: 60,
        activeDurationSeconds: 60,
        avgPower: 400,
        maxPower: 800,
        readingCount: 60,
        effortCount: 1,
        avgHeartRate: 175,
        maxHeartRate: 185,
        avgCadence: 105,
        avgLeftRightBalance: 48.5,
      );
      expect(s.avgHeartRate, 175);
      expect(s.maxHeartRate, 185);
      expect(s.avgCadence, 105.0);
      expect(s.avgLeftRightBalance, 48.5);
    });
  });
}
