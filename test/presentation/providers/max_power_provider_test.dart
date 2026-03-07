import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/presentation/providers/ble_service_provider.dart';
import 'package:wattalizer/presentation/providers/max_power_override_provider.dart';
import 'package:wattalizer/presentation/providers/max_power_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

import '../fixtures/fake_ble_service.dart';
import '../fixtures/fake_repository.dart';

// Minimal override notifier that returns a fixed value without touching prefs.
class _FixedOverride extends MaxPowerOverrideNotifier {
  _FixedOverride(this._value);
  final double? _value;

  @override
  double? build() => _value;
}

ProviderContainer _makeContainer({
  required FakeRepository repo,
  double? overrideValue,
}) {
  return ProviderContainer(
    overrides: [
      rideRepositoryProvider.overrideWithValue(repo),
      bleServiceProvider.overrideWithValue(FakeBleService()),
      maxPowerOverrideProvider
          .overrideWith(() => _FixedOverride(overrideValue)),
    ],
  );
}

void main() {
  group('maxPowerProvider', () {
    test('returns override value when override is set', () async {
      final container =
          _makeContainer(repo: FakeRepository(), overrideValue: 800);
      addTearDown(container.dispose);

      final power = await container.read(maxPowerProvider.future);

      expect(power, 800.0);
    });

    test('computes from effort curves when no override', () async {
      final repo = FakeRepository()
        ..effortCurvesToReturn = [
          MapCurveWithProvenance(
            effortId: 'e1',
            rideId: 'r1',
            rideDate: DateTime(2025),
            effortNumber: 1,
            curve: MapCurve(
              entityId: 'e1',
              values: List.generate(90, (i) => i == 0 ? 1200.0 : 900.0),
              flags: List.generate(90, (_) => const MapCurveFlags()),
              computedAt: DateTime(2025),
            ),
          ),
        ];
      final container = _makeContainer(repo: repo);
      addTearDown(container.dispose);

      final power = await container.read(maxPowerProvider.future);

      expect(power, 1200.0);
    });

    test('returns 1500 when no curves and no override', () async {
      final container = _makeContainer(repo: FakeRepository());
      addTearDown(container.dispose);

      final power = await container.read(maxPowerProvider.future);

      expect(power, 1500.0);
    });
  });
}
