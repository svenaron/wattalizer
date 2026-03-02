import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';

void main() {
  group('AutoLapConfig defaults', () {
    test('isDefault is false by default', () {
      const cfg = AutoLapConfig(
        id: 'c1',
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

  group('shortSprint preset', () {
    final cfg = AutoLapConfig.shortSprint();

    test('has expected id', () {
      expect(cfg.id, 'preset_short_sprint');
    });

    test('has high start delta', () {
      expect(cfg.startDeltaWatts, 200);
    });

    test('has short confirm time', () {
      expect(cfg.startConfirmSeconds, 1);
    });

    test('uses short windows', () {
      expect(cfg.preEffortBaselineWindow, 10);
      expect(cfg.inEffortTrailingWindow, 5);
    });
  });

  group('flying200 preset', () {
    final cfg = AutoLapConfig.flying200();

    test('has expected id', () {
      expect(cfg.id, 'preset_flying_200');
    });

    test('has medium start delta', () {
      expect(cfg.startDeltaWatts, 150);
    });

    test('has 2s confirm', () {
      expect(cfg.startConfirmSeconds, 2);
    });

    test('min effort is 5s', () {
      expect(cfg.minEffortSeconds, 5);
    });
  });

  group('teamSprint preset', () {
    final cfg = AutoLapConfig.teamSprint();

    test('has expected id', () {
      expect(cfg.id, 'preset_team_sprint');
    });

    test('has lower start delta for sustained efforts', () {
      expect(cfg.startDeltaWatts, 120);
    });

    test('has long min effort', () {
      expect(cfg.minEffortSeconds, 10);
    });

    test('uses wider windows', () {
      expect(cfg.preEffortBaselineWindow, 20);
      expect(cfg.inEffortTrailingWindow, 15);
    });
  });

  group('copyWith', () {
    test('preserves id and overrides name', () {
      final cfg = AutoLapConfig.flying200();
      final copy = cfg.copyWith(name: 'Custom 200');
      expect(copy.id, cfg.id);
      expect(copy.name, 'Custom 200');
      expect(copy.startDeltaWatts, cfg.startDeltaWatts);
    });

    test('can mark as default', () {
      final cfg = AutoLapConfig.shortSprint();
      final copy = cfg.copyWith(isDefault: true);
      expect(copy.isDefault, isTrue);
    });
  });

  group('custom id', () {
    test('shortSprint accepts custom id', () {
      final cfg = AutoLapConfig.shortSprint(id: 'my_id');
      expect(cfg.id, 'my_id');
    });
  });
}
