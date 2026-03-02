import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/core/constants.dart';

void main() {
  group('kMapDurations', () {
    test('has exactly 90 entries', () {
      expect(kMapDurations.length, 90);
    });

    test('starts at 1', () {
      expect(kMapDurations.first, 1);
    });

    test('ends at 90', () {
      expect(kMapDurations.last, 90);
    });

    test('is sequential with no gaps', () {
      for (var i = 0; i < kMapDurations.length; i++) {
        expect(kMapDurations[i], i + 1);
      }
    });
  });

  group('kMapDurationCount', () {
    test('equals 90', () {
      expect(kMapDurationCount, 90);
    });

    test('matches kMapDurations length', () {
      expect(kMapDurationCount, kMapDurations.length);
    });
  });

  group('default AutoLap config values', () {
    test('startConfirmSeconds is 2', () {
      expect(kDefaultStartConfirmSeconds, 2);
    });

    test('endConfirmSeconds is 5', () {
      expect(kDefaultEndConfirmSeconds, 5);
    });

    test('minEffortSeconds is 3', () {
      expect(kDefaultMinEffortSeconds, 3);
    });

    test('preEffortBaselineWindow is 15', () {
      expect(kDefaultPreEffortBaselineWindow, 15);
    });

    test('inEffortTrailingWindow is 10', () {
      expect(kDefaultInEffortTrailingWindow, 10);
    });
  });
}
