import 'package:drift/drift.dart';
import 'package:wattalizer/data/database/database.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/map_curve.dart';

enum EffortType { auto, manual }

class Effort {
  const Effort({
    required this.id,
    required this.rideId,
    required this.effortNumber,
    required this.startOffset,
    required this.endOffset,
    required this.type,
    required this.summary,
    required this.mapCurve,
  });

  factory Effort.fromRow(EffortRow row, MapCurve curve) {
    return Effort(
      id: row.id,
      rideId: row.rideId,
      effortNumber: row.effortNumber,
      startOffset: row.startOffset,
      endOffset: row.endOffset,
      type: row.type == 'auto' ? EffortType.auto : EffortType.manual,
      summary: EffortSummary(
        durationSeconds: row.durationSeconds,
        avgPower: row.avgPower,
        peakPower: row.peakPower,
        avgHeartRate: row.avgHeartRate,
        maxHeartRate: row.maxHeartRate,
        avgCadence: row.avgCadence,
        avgLeftRightBalance: row.avgLeftRightBalance,
        restSincePrevious: row.restSincePrevious,
      ),
      mapCurve: curve,
    );
  }

  EffortsCompanion toCompanion() {
    return EffortsCompanion.insert(
      id: id,
      rideId: rideId,
      effortNumber: effortNumber,
      startOffset: startOffset,
      endOffset: endOffset,
      type: type == EffortType.auto ? 'auto' : 'manual',
      durationSeconds: summary.durationSeconds,
      avgPower: summary.avgPower,
      peakPower: summary.peakPower,
      avgHeartRate: Value.absentIfNull(summary.avgHeartRate),
      maxHeartRate: Value.absentIfNull(summary.maxHeartRate),
      avgCadence: Value.absentIfNull(summary.avgCadence),
      avgLeftRightBalance: Value.absentIfNull(summary.avgLeftRightBalance),
      restSincePrevious: Value.absentIfNull(summary.restSincePrevious),
    );
  }

  final String id;
  final String rideId;
  final int effortNumber;
  final int startOffset;
  final int endOffset;
  final EffortType type;
  final EffortSummary summary;
  final MapCurve mapCurve;
}
