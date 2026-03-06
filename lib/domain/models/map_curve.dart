import 'package:drift/drift.dart';
import 'package:wattalizer/data/database/database.dart';

class MapCurveFlags {
  const MapCurveFlags({this.hadNulls = false, this.wasEnforced = false});

  final bool hadNulls;
  final bool wasEnforced;
}

class MapCurve {
  const MapCurve({
    required this.entityId,
    required this.values,
    required this.flags,
    required this.computedAt,
  });

  /// Reconstructs a MapCurve from 90 DB rows (one per duration 1–90s).
  factory MapCurve.fromRows(String entityId, List<MapCurveRow> rows) {
    final values = List<double>.filled(90, 0);
    final flags = List<MapCurveFlags>.generate(
      90,
      (_) => const MapCurveFlags(),
    );

    for (final row in rows) {
      final i = row.durationSeconds - 1; // duration 1 → index 0
      values[i] = row.bestAvgPower;
      flags[i] = MapCurveFlags(
        hadNulls: row.hadNulls,
        wasEnforced: row.wasEnforced,
      );
    }

    return MapCurve(
      entityId: entityId,
      values: values,
      flags: flags,
      computedAt: DateTime.now(),
    );
  }

  /// Converts to 90 Drift companions for batch insert (one per duration).
  List<MapCurvesCompanion> toCompanions() {
    return List.generate(
      90,
      (i) => MapCurvesCompanion.insert(
        effortId: entityId,
        durationSeconds: i + 1,
        bestAvgPower: values[i],
        hadNulls: Value(flags[i].hadNulls),
        wasEnforced: Value(flags[i].wasEnforced),
      ),
    );
  }

  final String entityId; // effort ID (or ride ID for ride-level PDC)
  final List<double> values; // 90 entries, index 0 = 1s best
  final List<MapCurveFlags> flags; // 90 entries, parallel to values
  final DateTime computedAt;
}
