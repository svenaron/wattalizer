import 'package:drift/drift.dart';
import 'package:wattalizer/core/error_types.dart';
import 'package:wattalizer/data/database/database.dart';
import 'package:wattalizer/data/database/local_ride_repository.dart';
import 'package:wattalizer/domain/interfaces/athlete_repository.dart';
import 'package:wattalizer/domain/models/athlete_profile.dart';

class LocalAthleteRepository implements AthleteRepository {
  LocalAthleteRepository(this._db, this._rides);
  final AppDatabase _db;
  final LocalRideRepository _rides;

  @override
  Future<List<AthleteProfile>> getAthletes() async {
    final rows = await (_db.select(_db.athletes)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map(AthleteProfile.fromRow).toList();
  }

  @override
  Future<AthleteProfile?> getAthlete(String id) async {
    final row = await (_db.select(_db.athletes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? AthleteProfile.fromRow(row) : null;
  }

  @override
  Future<void> saveAthlete(AthleteProfile athlete) async {
    await _db.into(_db.athletes).insert(athlete.toCompanion());
  }

  @override
  Future<void> updateAthlete(AthleteProfile athlete) async {
    await (_db.update(_db.athletes)..where((t) => t.id.equals(athlete.id)))
        .write(AthletesCompanion(name: Value(athlete.name)));
  }

  @override
  Future<void> deleteAthlete(String id) async {
    await _db.transaction(() async {
      final count = await _db
          .customSelect('SELECT COUNT(*) AS c FROM athletes')
          .getSingle();
      if (count.read<int>('c') <= 1) {
        throw AthleteDeleteRefused();
      }

      // Cascade: delete all rides (and their children) for this athlete
      final rideRows = await (_db.select(_db.rides)
            ..where((t) => t.athleteId.equals(id)))
          .get();
      for (final ride in rideRows) {
        await _rides.deleteRide(ride.id);
      }

      // Delete athlete-scoped devices
      await (_db.delete(_db.devices)..where((t) => t.athleteId.equals(id)))
          .go();

      // Delete athlete-scoped autolap configs
      await (_db.delete(_db.autolapConfigs)
            ..where((t) => t.athleteId.equals(id)))
          .go();

      await (_db.delete(_db.athletes)..where((t) => t.id.equals(id))).go();
    });
  }
}
