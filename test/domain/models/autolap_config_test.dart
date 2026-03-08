import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';

void main() {
  group('AutoLapConfig defaults', () {
    test('isDefault is false by default', () {
      const cfg = AutoLapConfig(
        name: 'Test',
        startDeltaWatts: 100,
        endDeltaWatts: 80,
      );
      expect(cfg.isDefault, isFalse);
      expect(cfg.startConfirmSeconds, 2);
      expect(cfg.startDropoutTolerance, 1);
      expect(cfg.endConfirmSeconds, 5);
      expect(cfg.minEffortSeconds, 3);
      expect(cfg.preEffortBaselineWindow, 15);
      expect(cfg.inEffortTrailingWindow, 10);
    });
  });

  group('standingStart preset', () {
    final cfg = AutoLapConfig.standingStart();

    test('has null id (unsaved)', () {
      expect(cfg.id, isNull);
    });

    test('has high start delta', () {
      expect(cfg.startDeltaWatts, 350);
    });

    test('has short confirm time', () {
      expect(cfg.startConfirmSeconds, 1);
    });

    test('uses short windows', () {
      expect(cfg.preEffortBaselineWindow, 10);
      expect(cfg.inEffortTrailingWindow, 5);
    });

    test('has min peak watts', () {
      expect(cfg.minPeakWatts, 700);
    });

    test('has correct end delta', () {
      expect(cfg.endDeltaWatts, 250);
    });
  });

  group('flyingStart preset', () {
    final cfg = AutoLapConfig.flyingStart();

    test('has null id (unsaved)', () {
      expect(cfg.id, isNull);
    });

    test('has low start delta for wind-up entry', () {
      expect(cfg.startDeltaWatts, 150);
    });

    test('has 2s confirm', () {
      expect(cfg.startConfirmSeconds, 2);
    });

    test('min effort is 5s', () {
      expect(cfg.minEffortSeconds, 5);
    });

    test('has min peak watts', () {
      expect(cfg.minPeakWatts, 700);
    });
  });

  group('broad preset', () {
    final cfg = AutoLapConfig.broad();

    test('has null id (unsaved)', () {
      expect(cfg.id, isNull);
    });

    test('has lower start delta', () {
      expect(cfg.startDeltaWatts, 120);
    });

    test('has short min effort', () {
      expect(cfg.minEffortSeconds, 2);
    });

    test('uses standard windows', () {
      expect(cfg.preEffortBaselineWindow, 15);
      expect(cfg.inEffortTrailingWindow, 8);
    });

    test('has min peak watts', () {
      expect(cfg.minPeakWatts, 400);
    });
  });

  group('copyWith', () {
    test('preserves id and overrides name', () {
      const cfg = AutoLapConfig(
        id: 1,
        name: 'Flying Start',
        startDeltaWatts: 150,
        endDeltaWatts: 150,
      );
      final copy = cfg.copyWith(name: 'Custom 200');
      expect(copy.id, cfg.id);
      expect(copy.name, 'Custom 200');
      expect(copy.startDeltaWatts, cfg.startDeltaWatts);
    });

    test('can mark as default', () {
      const cfg = AutoLapConfig(
        id: 1,
        name: 'Standing Start',
        startDeltaWatts: 350,
        endDeltaWatts: 250,
      );
      final copy = cfg.copyWith(isDefault: true);
      expect(copy.isDefault, isTrue);
    });

    test('can clear minPeakWatts to null', () {
      final cfg = AutoLapConfig.standingStart();
      final copy = cfg.copyWith(minPeakWatts: null);
      expect(copy.minPeakWatts, isNull);
    });

    test('preserves minPeakWatts when not passed', () {
      final cfg = AutoLapConfig.standingStart();
      final copy = cfg.copyWith(name: 'X');
      expect(copy.minPeakWatts, cfg.minPeakWatts);
    });
  });
}
