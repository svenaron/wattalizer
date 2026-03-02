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

  final String entityId; // effort ID (or ride ID for ride-level PDC)
  final List<double> values; // 90 entries, index 0 = 1s best
  final List<MapCurveFlags> flags; // 90 entries, parallel to values
  final DateTime computedAt;
}
