import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/data/database/database.dart';
import 'package:wattalizer/data/database/local_ride_repository.dart';
import 'package:wattalizer/data/database/scoped_ride_repository.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';

AppDatabase _openInMemory() => AppDatabase(NativeDatabase.memory());

Ride _makeRide(String id, {DateTime? startTime}) => Ride(
      id: id,
      startTime: startTime ?? DateTime(2024),
      source: RideSource.recorded,
      summary: const RideSummary(
        durationSeconds: 60,
        activeDurationSeconds: 30,
        avgPower: 300,
        maxPower: 800,
        readingCount: 60,
        effortCount: 0,
      ),
    );

void main() {
  late AppDatabase db;
  late LocalRideRepository inner;
  late ScopedRideRepository scopedA;
  late ScopedRideRepository scopedB;

  setUp(() {
    db = _openInMemory();
    inner = LocalRideRepository(db);
    scopedA = ScopedRideRepository(inner, 'athleteA');
    scopedB = ScopedRideRepository(inner, 'athleteB');
  });

  tearDown(() async {
    await db.close();
  });

  group('isolation', () {
    test('rides from other athlete are invisible', () async {
      await scopedA.saveRide(_makeRide('r1'));
      final visible = await scopedB.getRides();
      expect(visible, isEmpty);
    });

    test('each athlete sees only their own rides', () async {
      await scopedA.saveRide(_makeRide('rA'));
      await scopedB.saveRide(_makeRide('rB'));

      final forA = await scopedA.getRides();
      final forB = await scopedB.getRides();

      expect(forA.map((r) => r.id), contains('rA'));
      expect(forA.map((r) => r.id), isNot(contains('rB')));
      expect(forB.map((r) => r.id), contains('rB'));
      expect(forB.map((r) => r.id), isNot(contains('rA')));
    });

    test('getRideCount is scoped', () async {
      await scopedA.saveRide(_makeRide('r1'));
      await scopedA.saveRide(_makeRide('r2'));
      await scopedB.saveRide(_makeRide('r3'));

      expect(await scopedA.getRideCount(), 2);
      expect(await scopedB.getRideCount(), 1);
    });
  });

  group('non-scoped operations', () {
    test('getRide by id works across scopes', () async {
      await scopedA.saveRide(_makeRide('rA'));
      final ride = await scopedB.getRide('rA');
      expect(ride?.id, 'rA');
    });

    test('deleteRide works from either scope', () async {
      await scopedA.saveRide(_makeRide('rA'));
      await scopedB.deleteRide('rA');
      expect(await scopedA.getRide('rA'), isNull);
    });
  });
}
