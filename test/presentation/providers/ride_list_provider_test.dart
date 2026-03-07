import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/history_span.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/presentation/providers/ride_list_provider.dart';
import 'package:wattalizer/presentation/providers/span_selection_provider.dart';
import 'package:wattalizer/presentation/providers/tag_filter_provider.dart';

import '../fixtures/fake_repository.dart';
import '../fixtures/test_container.dart';

RideSummaryRow _makeRow(String id) => RideSummaryRow(
      id: id,
      startTime: DateTime(2025),
      tags: const [],
      summary: const RideSummary(
        durationSeconds: 60,
        activeDurationSeconds: 30,
        avgPower: 400,
        maxPower: 800,
        readingCount: 60,
        effortCount: 1,
      ),
    );

void main() {
  group('rideListProvider', () {
    test('returns list from repository', () async {
      final repo = FakeRepository()..ridesToReturn = [_makeRow('r1')];
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final rides = await container.read(rideListProvider.future);

      expect(rides, hasLength(1));
      expect(rides.first.id, 'r1');
    });

    test('allTime span passes null from to getRides', () async {
      final repo = FakeRepository();
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      // Default span is allTime
      await container.read(rideListProvider.future);

      expect(repo.getRidesCalls, hasLength(1));
      expect(repo.getRidesCalls.first.from, isNull);
    });

    test('week span passes a from date 7 days ago', () async {
      final repo = FakeRepository();
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      container.read(spanSelectionProvider.notifier).span = HistorySpan.week;
      await container.read(rideListProvider.future);

      expect(repo.getRidesCalls, hasLength(1));
      final call = repo.getRidesCalls.first;
      expect(call.from, isNotNull);
      // from should be approximately 7 days ago
      final diff = DateTime.now().difference(call.from!);
      expect(diff.inDays, closeTo(7, 1));
    });

    test('passes tags from tagFilterProvider', () async {
      final repo = FakeRepository();
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      container.read(tagFilterProvider.notifier).addTag('track');
      await container.read(rideListProvider.future);

      expect(repo.getRidesCalls.first.tags, {'track'});
    });

    test('empty tag filter passes null tags to getRides', () async {
      final repo = FakeRepository();
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      await container.read(rideListProvider.future);

      expect(repo.getRidesCalls.first.tags, isNull);
    });
  });
}
