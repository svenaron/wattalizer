import 'package:drift/drift.dart';
import 'package:wattalizer/data/database/database.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';

enum RideSource { recorded, importedTcx, importedFit }

class Ride {
  const Ride({
    required this.id,
    required this.startTime,
    required this.source,
    required this.summary,
    this.endTime,
    this.tags = const [],
    this.notes,
    this.efforts = const [],
  });

  factory Ride.fromRow(RideRow row, List<String> tags, List<Effort> efforts) {
    return Ride(
      id: row.id,
      startTime: row.startTime,
      endTime: row.endTime,
      tags: tags,
      notes: row.notes,
      source: switch (row.source) {
        'recorded' => RideSource.recorded,
        'imported_fit' => RideSource.importedFit,
        _ => RideSource.importedTcx,
      },
      efforts: efforts,
      summary: RideSummary(
        durationSeconds: row.durationSeconds,
        activeDurationSeconds: row.activeDurationSeconds,
        avgPower: row.avgPower,
        maxPower: row.maxPower,
        avgHeartRate: row.avgHeartRate,
        maxHeartRate: row.maxHeartRate,
        avgCadence: row.avgCadence,
        avgLeftRightBalance: row.avgLeftRightBalance,
        readingCount: row.readingCount,
        effortCount: row.effortCount,
      ),
    );
  }

  RidesCompanion toCompanion() {
    return RidesCompanion.insert(
      id: id,
      startTime: startTime,
      endTime: Value.absentIfNull(endTime),
      notes: Value.absentIfNull(notes),
      source: switch (source) {
        RideSource.recorded => 'recorded',
        RideSource.importedTcx => 'imported_tcx',
        RideSource.importedFit => 'imported_fit',
      },
      durationSeconds: summary.durationSeconds,
      activeDurationSeconds: summary.activeDurationSeconds,
      avgPower: summary.avgPower,
      maxPower: summary.maxPower,
      avgHeartRate: Value.absentIfNull(summary.avgHeartRate),
      maxHeartRate: Value.absentIfNull(summary.maxHeartRate),
      avgCadence: Value.absentIfNull(summary.avgCadence),
      avgLeftRightBalance: Value.absentIfNull(summary.avgLeftRightBalance),
      readingCount: summary.readingCount,
      effortCount: summary.effortCount,
    );
  }

  Ride copyWith({
    List<String>? tags,
    String? notes,
    List<Effort>? efforts,
    RideSummary? summary,
  }) {
    return Ride(
      id: id,
      startTime: startTime,
      endTime: endTime,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      source: source,
      efforts: efforts ?? this.efforts,
      summary: summary ?? this.summary,
    );
  }

  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> tags;
  final String? notes;
  final RideSource source;
  final List<Effort> efforts; // loaded eagerly on detail, empty on list
  final RideSummary summary;
}
