import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/presentation/providers/ride_pdc_provider.dart';

import '../fixtures/fake_repository.dart';
import '../fixtures/test_container.dart';

Effort _effort(String id, String rideId, List<double> values) {
  return Effort(
    id: id,
    rideId: rideId,
    effortNumber: 1,
    startOffset: 0,
    endOffset: 30,
    type: EffortType.auto,
    summary: const EffortSummary(
      durationSeconds: 30,
      avgPower: 0,
      peakPower: 0,
    ),
    mapCurve: MapCurve(
      entityId: id,
      values: values,
      flags: List.generate(90, (_) => const MapCurveFlags()),
      computedAt: DateTime(2025),
    ),
  );
}

void main() {
  group('ridePdcProvider', () {
    test('returns null when no efforts stored', () async {
      final container = createTestContainer(repository: FakeRepository());
      addTearDown(container.dispose);

      final pdc = await container.read(ridePdcProvider('r1').future);

      expect(pdc, isNull);
    });

    test('returns PDC derived from effort curves', () async {
      final repo = FakeRepository()
        ..effortsByRide = {
          'r1': [
            _effort('e1', 'r1', List.generate(90, (i) => 500.0 - i * 2)),
          ],
        };
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final pdc = await container.read(ridePdcProvider('r1').future);

      expect(pdc, isNotNull);
      expect(pdc!.entityId, 'r1');
      expect(pdc.values[0], 500.0);
    });

    test('takes max power across multiple efforts at each duration', () async {
      final repo = FakeRepository()
        ..effortsByRide = {
          'r1': [
            _effort('e1', 'r1', List.generate(90, (_) => 400.0)),
            _effort('e2', 'r1', List.generate(90, (_) => 600.0)),
          ],
        };
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final pdc = await container.read(ridePdcProvider('r1').future);

      expect(pdc!.values[0], 600.0);
      expect(pdc.values[89], 600.0);
    });

    test('family parameter routes to correct ride efforts', () async {
      final repo = FakeRepository()
        ..effortsByRide = {
          'r1': [
            _effort('e1', 'r1', List.generate(90, (_) => 500.0)),
          ],
          'r2': [
            _effort('e2', 'r2', List.generate(90, (_) => 700.0)),
          ],
        };
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final pdc1 = await container.read(ridePdcProvider('r1').future);
      final pdc2 = await container.read(ridePdcProvider('r2').future);

      expect(pdc1!.values[0], 500.0);
      expect(pdc2!.values[0], 700.0);
    });

    test('enforces monotonicity on computed PDC', () async {
      // Non-monotonic input: 300 at 1s, 400 at 2s (should be flattened)
      final nonMono = List<double>.filled(90, 100);
      nonMono[0] = 300.0;
      nonMono[1] = 400.0; // higher than 1s — monotonicity fix needed
      final repo = FakeRepository()
        ..effortsByRide = {
          'r1': [_effort('e1', 'r1', nonMono)],
        };
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final pdc = await container.read(ridePdcProvider('r1').future);

      // After monotonicity sweep, values[0] should be >= values[1]
      expect(pdc!.values[0], greaterThanOrEqualTo(pdc.values[1]));
    });
  });
}
