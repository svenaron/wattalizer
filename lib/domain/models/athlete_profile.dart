import 'package:drift/drift.dart';
import 'package:wattalizer/data/database/database.dart';

class AthleteProfile {
  const AthleteProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    this.coachId,
  });

  factory AthleteProfile.fromRow(AthleteRow row) => AthleteProfile(
        id: row.id,
        name: row.name,
        createdAt: row.createdAt,
        coachId: row.coachId,
      );

  AthletesCompanion toCompanion() => AthletesCompanion.insert(
        id: id,
        name: name,
        createdAt: createdAt,
        coachId: Value.absentIfNull(coachId),
      );

  AthleteProfile copyWith({String? name}) => AthleteProfile(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        coachId: coachId,
      );

  final String id;
  final String name;
  final DateTime createdAt;
  final String? coachId;
}
