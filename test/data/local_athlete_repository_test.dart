import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/core/error_types.dart';
import 'package:wattalizer/data/database/database.dart';
import 'package:wattalizer/data/database/local_athlete_repository.dart';
import 'package:wattalizer/data/database/local_ride_repository.dart';
import 'package:wattalizer/domain/models/athlete_profile.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';

AppDatabase _openInMemory() => AppDatabase(NativeDatabase.memory());

AthleteProfile _makeAthlete(String id, {String name = 'Test'}) =>
    AthleteProfile(
      id: id,
      name: name,
      createdAt: DateTime(2024),
    );

Ride _makeRide(String id) => Ride(
      id: id,
      startTime: DateTime(2024),
      source: RideSource.recorded,
      summary: const RideSummary(
        durationSeconds: 60,
        activeDurationSeconds: 30,
        avgPower: 300,
        maxPower: 800,
        readingCount: 60,
        effortCount: 1,
      ),
    );

void main() {
  late AppDatabase db;
  late LocalRideRepository rides;
  late LocalAthleteRepository repo;

  setUp(() {
    db = _openInMemory();
    rides = LocalRideRepository(db);
    repo = LocalAthleteRepository(db, rides);
    // The in-memory DB seeds 'me' in onCreate automatically.
  });

  tearDown(() async {
    await db.close();
  });

  group('getAthletes', () {
    test('returns seeded athlete', () async {
      final athletes = await repo.getAthletes();
      expect(athletes, hasLength(1));
      expect(athletes.first.id, 'me');
    });

    test('returns multiple athletes sorted by name', () async {
      await repo.saveAthlete(_makeAthlete('b', name: 'Bob'));
      await repo.saveAthlete(_makeAthlete('a', name: 'Alice'));
      final names = (await repo.getAthletes()).map((a) => a.name).toList();
      expect(names, ['Alice', 'Bob', 'Me']);
    });
  });

  group('saveAthlete / getAthlete', () {
    test('round-trip', () async {
      final a = _makeAthlete('alice', name: 'Alice');
      await repo.saveAthlete(a);
      final fetched = await repo.getAthlete('alice');
      expect(fetched?.name, 'Alice');
    });

    test('getAthlete returns null for unknown id', () async {
      expect(await repo.getAthlete('nope'), isNull);
    });
  });

  group('updateAthlete', () {
    test('updates name', () async {
      final a = _makeAthlete('me', name: 'Me');
      await repo.updateAthlete(a.copyWith(name: 'Updated'));
      final updated = await repo.getAthlete('me');
      expect(updated?.name, 'Updated');
    });
  });

  group('deleteAthlete', () {
    test('throws AthleteDeleteRefused when only one athlete', () async {
      expect(
        () => repo.deleteAthlete('me'),
        throwsA(isA<AthleteDeleteRefused>()),
      );
    });

    test('deletes athlete when others exist', () async {
      await repo.saveAthlete(_makeAthlete('alice'));
      await repo.deleteAthlete('alice');
      expect(await repo.getAthlete('alice'), isNull);
    });

    test('cascade deletes rides for deleted athlete', () async {
      await repo.saveAthlete(_makeAthlete('alice'));
      await rides.saveRideForAthlete(_makeRide('r1'), 'alice');
      await repo.deleteAthlete('alice');
      expect(await rides.getRide('r1'), isNull);
    });
  });
}
