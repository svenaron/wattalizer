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
