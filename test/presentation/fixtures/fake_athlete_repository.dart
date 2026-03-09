import 'package:wattalizer/domain/interfaces/athlete_repository.dart';
import 'package:wattalizer/domain/models/athlete_profile.dart';

class FakeAthleteRepository implements AthleteRepository {
  List<AthleteProfile> athletes = [
    AthleteProfile(
      id: 'me',
      name: 'Me',
      createdAt: DateTime(2024),
    ),
  ];

  @override
  Future<List<AthleteProfile>> getAthletes() async => athletes;

  @override
  Future<AthleteProfile?> getAthlete(String id) async =>
      athletes.where((a) => a.id == id).firstOrNull;

  @override
  Future<void> saveAthlete(AthleteProfile athlete) async =>
      athletes.add(athlete);

  @override
  Future<void> updateAthlete(AthleteProfile athlete) async {
    final idx = athletes.indexWhere((a) => a.id == athlete.id);
    if (idx >= 0) athletes[idx] = athlete;
  }

  @override
  Future<void> deleteAthlete(String id) async =>
      athletes.removeWhere((a) => a.id == id);
}
