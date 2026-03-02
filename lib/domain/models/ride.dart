import 'package:drift/drift.dart';
import 'package:wattalizer/data/database/database.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';

enum RideSource { recorded, importedTcx }

class Ride {
  const Ride({
    required this.id,
    required this.startTime,
    required this.source,
    required this.summary,
    this.endTime,
    this.tags = const [],
    this.notes,
    this.autoLapConfigId,
    this.efforts = const [],
  });

  factory Ride.fromRow(RideRow row, List<String> tags, List<Effort> efforts) {
    return Ride(
      id: row.id,
      startTime: row.startTime,
      endTime: row.endTime,
      tags: tags,
      notes: row.notes,
      source: row.source == 'recorded'
          ? RideSource.recorded
          : RideSource.importedTcx,
      autoLapConfigId: row.autoLapConfigId,
      efforts: efforts,
      summary: RideSummary(
        durationSeconds: row.durationSeconds,
        activeDurationSeconds: row.activeDurationSeconds,
        avgPower: row.avgPower,
        maxPower: row.maxPower,
        avgHeartRate: row.avgHeartRate,
        maxHeartRate: row.maxHeartRate,
        avgCadence: row.avgCadence,
        totalKilojoules: row.totalKilojoules,
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
      source: source == RideSource.recorded ? 'recorded' : 'imported_tcx',
      autoLapConfigId: Value.absentIfNull(autoLapConfigId),
      durationSeconds: summary.durationSeconds,
      activeDurationSeconds: summary.activeDurationSeconds,
      avgPower: summary.avgPower,
      maxPower: summary.maxPower,
      avgHeartRate: Value.absentIfNull(summary.avgHeartRate),
      maxHeartRate: Value.absentIfNull(summary.maxHeartRate),
      avgCadence: Value.absentIfNull(summary.avgCadence),
      totalKilojoules: summary.totalKilojoules,
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
    String? autoLapConfigId,
  }) {
    return Ride(
      id: id,
      startTime: startTime,
      endTime: endTime,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      source: source,
      autoLapConfigId: autoLapConfigId ?? this.autoLapConfigId,
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
  final String? autoLapConfigId;
  final List<Effort> efforts; // loaded eagerly on detail, empty on list
  final RideSummary summary;
}
