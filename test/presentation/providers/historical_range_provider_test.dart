import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/history_span.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/presentation/providers/historical_range_provider.dart';
import 'package:wattalizer/presentation/providers/span_selection_provider.dart';
import 'package:wattalizer/presentation/providers/tag_filter_provider.dart';

import '../fixtures/fake_repository.dart';
import '../fixtures/test_container.dart';

MapCurveWithProvenance _makeCurve(String effortId, double peakPower) =>
    MapCurveWithProvenance(
      effortId: effortId,
      rideId: 'r1',
      rideDate: DateTime(2025),
      effortNumber: 1,
      curve: MapCurve(
        entityId: effortId,
        values: List.generate(90, (i) => peakPower - i * 2),
        flags: List.generate(90, (_) => const MapCurveFlags()),
        computedAt: DateTime(2025),
      ),
    );

void main() {
  group('historicalRangeProvider', () {
    test('returns null when no effort curves', () async {
      final container = createTestContainer(repository: FakeRepository());
      addTearDown(container.dispose);

      final range = await container.read(historicalRangeProvider.future);

      expect(range, isNull);
    });

    test('computes range when curves available', () async {
      final repo = FakeRepository()
        ..effortCurvesToReturn = [
          _makeCurve('e1', 1000),
          _makeCurve('e2', 800),
        ];
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final range = await container.read(historicalRangeProvider.future);

      expect(range, isNotNull);
      expect(range!.effortCount, 2);
      // Best 1s should be the higher value (1000)
      expect(range.best[0].power, 1000.0);
      // Worst 1s should be the lower value (800)
      expect(range.worst[0].power, 800.0);
    });

    test('passes span and tag filters to repository', () async {
      final repo = FakeRepository();
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      container.read(spanSelectionProvider.notifier).span = HistorySpan.week;
      container.read(tagFilterProvider.notifier).addTag('track');
      await container.read(historicalRangeProvider.future);

      expect(repo.getAllEffortCurvesCalls, hasLength(1));
      final call = repo.getAllEffortCurvesCalls.first;
      expect(call.from, isNotNull);
      expect(call.tags, {'track'});
    });

    test('allTime span passes null from date', () async {
      final repo = FakeRepository();
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      await container.read(historicalRangeProvider.future);

      expect(repo.getAllEffortCurvesCalls.first.from, isNull);
    });
  });
}
