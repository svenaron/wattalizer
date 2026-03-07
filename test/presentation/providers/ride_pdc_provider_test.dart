import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/presentation/providers/ride_pdc_provider.dart';

import '../fixtures/fake_repository.dart';
import '../fixtures/test_container.dart';

void main() {
  group('ridePdcProvider', () {
    test('returns null when no PDC stored', () async {
      final container = createTestContainer(repository: FakeRepository());
      addTearDown(container.dispose);

      final pdc = await container.read(ridePdcProvider('r1').future);

      expect(pdc, isNull);
    });

    test('returns PDC when available', () async {
      final repo = FakeRepository()
        ..ridePdcs = {
          'r1': MapCurve(
            entityId: 'r1',
            values: List.generate(90, (i) => 500.0 - i * 2),
            flags: List.generate(90, (_) => const MapCurveFlags()),
            computedAt: DateTime(2025),
          ),
        };
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final pdc = await container.read(ridePdcProvider('r1').future);

      expect(pdc, isNotNull);
      expect(pdc!.entityId, 'r1');
      expect(pdc.values[0], 500.0);
    });

    test('family parameter routes to correct ride PDC', () async {
      final repo = FakeRepository()
        ..ridePdcs = {
          'r1': MapCurve(
            entityId: 'r1',
            values: List.generate(90, (_) => 500.0),
            flags: List.generate(90, (_) => const MapCurveFlags()),
            computedAt: DateTime(2025),
          ),
          'r2': MapCurve(
            entityId: 'r2',
            values: List.generate(90, (_) => 700.0),
            flags: List.generate(90, (_) => const MapCurveFlags()),
            computedAt: DateTime(2025),
          ),
        };
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final pdc1 = await container.read(ridePdcProvider('r1').future);
      final pdc2 = await container.read(ridePdcProvider('r2').future);

      expect(pdc1!.values[0], 500.0);
      expect(pdc2!.values[0], 700.0);
    });
  });
}
