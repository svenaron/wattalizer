import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/presentation/providers/ride_detail_provider.dart';

import '../fixtures/fake_repository.dart';
import '../fixtures/test_container.dart';

Ride _makeRide(String id) => Ride(
      id: id,
      startTime: DateTime(2025),
      endTime: DateTime(2025, 1, 1, 0, 1),
      source: RideSource.recorded,
      summary: const RideSummary(
        durationSeconds: 60,
        activeDurationSeconds: 30,
        avgPower: 400,
        maxPower: 800,
        readingCount: 60,
        effortCount: 0,
      ),
    );

void main() {
  group('rideDetailProvider', () {
    test('returns ride when found', () async {
      final repo = FakeRepository()..ridesById = {'r1': _makeRide('r1')};
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final ride = await container.read(rideDetailProvider('r1').future);

      expect(ride, isNotNull);
      expect(ride!.id, 'r1');
    });

    test('returns null when not found', () async {
      final container = createTestContainer(repository: FakeRepository());
      addTearDown(container.dispose);

      final ride = await container.read(rideDetailProvider('missing').future);

      expect(ride, isNull);
    });

    test('family parameter routes to correct ride', () async {
      final repo = FakeRepository()
        ..ridesById = {
          'r1': _makeRide('r1'),
          'r2': _makeRide('r2'),
        };
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final r1 = await container.read(rideDetailProvider('r1').future);
      final r2 = await container.read(rideDetailProvider('r2').future);

      expect(r1!.id, 'r1');
      expect(r2!.id, 'r2');
    });
  });
}
