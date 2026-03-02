import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';

void main() {
  group('EffortSummary', () {
    test('constructs with required fields', () {
      const s = EffortSummary(
        durationSeconds: 15,
        avgPower: 800,
        peakPower: 1200,
        totalKilojoules: 12,
      );
      expect(s.durationSeconds, 15);
      expect(s.avgPower, 800.0);
      expect(s.peakPower, 1200.0);
      expect(s.totalKilojoules, 12.0);
    });

    test('optional fields default to null', () {
      const s = EffortSummary(
        durationSeconds: 10,
        avgPower: 0,
        peakPower: 0,
        totalKilojoules: 0,
      );
      expect(s.avgHeartRate, isNull);
      expect(s.maxHeartRate, isNull);
      expect(s.avgCadence, isNull);
      expect(s.avgLeftRightBalance, isNull);
      expect(s.restSincePrevious, isNull);
    });

    test('restSincePrevious can be set', () {
      const s = EffortSummary(
        durationSeconds: 12,
        avgPower: 700,
        peakPower: 900,
        totalKilojoules: 8.4,
        restSincePrevious: 120,
      );
      expect(s.restSincePrevious, 120);
    });
  });
}
