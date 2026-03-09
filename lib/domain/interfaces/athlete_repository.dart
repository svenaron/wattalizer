import 'package:wattalizer/core/error_types.dart' show AthleteDeleteRefused;
import 'package:wattalizer/domain/models/athlete_profile.dart';

abstract class AthleteRepository {
  Future<List<AthleteProfile>> getAthletes();
  Future<AthleteProfile?> getAthlete(String id);
  Future<void> saveAthlete(AthleteProfile athlete);
  Future<void> updateAthlete(AthleteProfile athlete);

  /// Throws [AthleteDeleteRefused] if this is the last athlete.
  /// Cascade-deletes all rides belonging to this athlete.
  Future<void> deleteAthlete(String id);
}
